#' Plot posterior distribution from dataframe of posterior draws.
#' @description
#' `r lifecycle::badge('stable')`
#'
#' Plot the posterior distribution of all latent parameters using a dataframe of posterior draws from a `causact_graph` model.
#' @param drawsDF the dataframe output of `dag_numpyro(mcmc=TRUE)` where each column is a parameter and each row a single draw from a representative sample.
#' @param densityPlot If `TRUE`, each parameter gets its own density plot.  If `FALSE` (recommended usage), parameters are grouped into facets based on whether they share the same prior or not.  10 and 90 percent credible intervals are displayed for the posterior distributions.
#' @param abbrevLabels If `TRUE`, long labels on the plot are abbreviated to 10 characters.  If `FALSE` the entire label is used.
#' @return a credible interval plot of all latent posterior distribution parameters.
#' @examples
#' # A simple example
#' posteriorDF = data.frame(x = rnorm(100),
#' y = rexp(100),
#' z = runif(100))
#' posteriorDF %>%
#' dagp_plot(densityPlot = TRUE)
#'
#' # More complicated example requiring 'numpyro'
#' \dontrun{
#' # Create a 2 node graph
#' graph = dag_create() %>%
#'   dag_node("Get Card","y",
#'          rhs = bernoulli(theta),
#'          data = carModelDF$getCard) %>%
#'   dag_node(descr = "Card Probability by Car",label = "theta",
#'            rhs = beta(2,2),
#'            child = "y")
#' graph %>% dag_render()
#'
#' # below requires Tensorflow installation
#' drawsDF = graph %>% dag_numpyro(mcmc=TRUE)
#' drawsDF %>% dagp_plot()
#' }
#'
#' # A multiple plate example
#' library(dplyr)
#' poolTimeGymDF = gymDF %>%
#' mutate(stretchType = ifelse(yogaStretch == 1,
#'                             "Yoga Stretch",
#'                             "Traditional")) %>%
#' group_by(gymID,stretchType,yogaStretch) %>%
#'   summarize(nTrialCustomers = sum(nTrialCustomers),
#'             nSigned = sum(nSigned))
#' graph = dag_create() %>%
#'   dag_node("Cust Signed","k",
#'            rhs = binomial(n,p),
#'            data = poolTimeGymDF$nSigned) %>%
#'   dag_node("Probability of Signing","p",
#'            rhs = beta(2,2),
#'            child = "k") %>%
#'   dag_node("Trial Size","n",
#'            data = poolTimeGymDF$nTrialCustomers,
#'            child = "k") %>%
#'   dag_plate("Yoga Stretch","x",
#'             nodeLabels = c("p"),
#'             data = poolTimeGymDF$stretchType,
#'             addDataNode = TRUE) %>%
#'   dag_plate("Observation","i",
#'             nodeLabels = c("x","k","n")) %>%
#'   dag_plate("Gym","j",
#'             nodeLabels = "p",
#'             data = poolTimeGymDF$gymID,
#'             addDataNode = TRUE)
#' graph %>% dag_render()
#' \dontrun{
#' # below requires Tensorflow installation
#' drawsDF = graph %>% dag_numpyro(mcmc=TRUE)
#' drawsDF %>% dagp_plot()
#' }
#' @importFrom dplyr bind_rows filter group_by
#' @importFrom rlang is_empty UQ enexpr enquo expr_text quo_name eval_tidy .data
#' @importFrom ggplot2 ggplot geom_density facet_wrap aes theme_minimal theme scale_alpha_continuous guides labs geom_segment element_blank after_stat
#' @importFrom tidyr gather
#' @importFrom cowplot plot_grid
#' @importFrom stats quantile
#' @importFrom lifecycle badge
#' @export


dagp_plot = function(drawsDF,densityPlot = FALSE, abbrevLabels = FALSE) { # case where untidy posterior draws are provided
  q95 <- density <- reasonableIntervalWidth <- credIQR <- shape <- param <- NULL ## place holder to pass devtools::check

  if (densityPlot == TRUE) {
    if (abbrevLabels) {  ## shorten labels if desired
      drawsDF = drawsDF %>%
        tidyr::gather() %>%
        dplyr::mutate(key = abbreviate(key, minlength = 10))} else {
          drawsDF = drawsDF %>%
            tidyr::gather()
        }
    plot = drawsDF %>% ## start with tidy draws
      ggplot2::ggplot(ggplot2::aes(x = value,
                          y = ggplot2::after_stat(density))) +
      ggplot2::geom_density(ggplot2::aes(fill = key)) +
      ggplot2::facet_wrap( ~ key, scales = "free_x") +
      ggplot2::theme_minimal() +
      ggplot2::theme(legend.position = "none")

    plot
  } else { # case where tidy posterior draws are provided
    plotList = list()
    ## filter out NA's like from LKJ prior (we do not know how to plot this)
    tryCatch({
      if (abbrevLabels) {  ## shorten labels if desired
        drawsDF = drawsDF %>%
          addPriorGroups() %>%
          dplyr::mutate(param = abbreviate(param, minlength = 10))} else {
            drawsDF = drawsDF %>%
              addPriorGroups()
          }
      drawsDF = drawsDF %>%
        dplyr::mutate(priorGroup = ifelse(is.na(priorGroup),999999,priorGroup)) %>%
      dplyr::filter(!is.na(priorGroup)) ##if try works, erase this line
    priorGroups = unique(drawsDF$priorGroup)
    numPriorGroups = length(priorGroups)
    for (i in 1:numPriorGroups) {
      df = drawsDF %>% dplyr::filter(priorGroup == priorGroups[i])

      # create one plot per group
      # groups defined as params with same prior
      plotList[[i]] = df %>% dplyr::group_by(param) %>%
        dplyr::summarize(q05 = stats::quantile(value,0.05),
                  q25 = stats::quantile(value,0.55),
                  q45 = stats::quantile(value,0.45),
                  q50 = stats::quantile(value,0.50),
                  q55 = stats::quantile(value,0.55),
                  q75 = stats::quantile(value,0.75),
                  q95 = stats::quantile(value,0.95)) %>%
        dplyr::mutate(credIQR = q75 - q25) %>%
        dplyr::mutate(reasonableIntervalWidth = 1.5 * stats::quantile(credIQR,0.75)) %>%
        dplyr::mutate(alphaLevel = ifelse(.data$credIQR > .data$reasonableIntervalWidth, 0.3,1)) %>%
        dplyr::arrange(alphaLevel,.data$q50) %>%
        dplyr::mutate(param = factor(param, levels = param)) %>%
        ggplot2::ggplot(ggplot2::aes(y = param, yend = param)) +
        ggplot2::geom_segment(ggplot2::aes(x = q05, xend = q95, alpha = alphaLevel), linewidth = 4, color = "#5f9ea0") +
        ggplot2::geom_segment(ggplot2::aes(x = q45, xend = q55, alpha = alphaLevel), linewidth = 4, color = "#11114e") +
        ggplot2::scale_alpha_continuous(range = c(0.6,1))  +
        ggplot2::guides(alpha = "none") +
        ggplot2::theme_minimal(12) +
        ggplot2::labs(y = ggplot2::element_blank(),
             x = "parameter value",
             caption = ifelse(i == numPriorGroups,"Credible Intervals - 10% (dark) & 90% (light)",""))

    }

    nCol <- ifelse(numPriorGroups==1,1,floor(1 + sqrt(numPriorGroups)))
    cowplot::plot_grid(plotlist = plotList, ncol = nCol)
    },
    error = function(c) dagp_plot(drawsDF, densityPlot = T)) # end try
  } # end else
} # end function

#' Render the graph as an htmlwidget
#'
#' @description
#' `r lifecycle::badge('stable')`
#'
#' Using a `causact_graph` object, render the graph in the RStudio Viewer.
#' @param graph a graph object of class `dgr_graph`.
#' @param shortLabel a logical value.  If set to `TRUE`, distribution and formula information is suppressed.  Meant for communication with non-statistical stakeholders.
#' @param wrapWidth a numeric value.  Used to restrict width of nodes.  Default is wrap text after 24 characters.
#' @param width a numeric value.  an optional parameter for specifying the width of the resulting graphic in pixels.
#' @param height a numeric value.  an optional parameter for specifying the height of the resulting graphic in pixels.
#' @param fillColor a valid R color to be used as the default node fill color during `dag_render()`.
#' @param fillColorObs a valid R color to be used as the fill color for observed nodes during `dag_render()`.
#' @examples
#' # Render a simple graph
#' dag_create() %>%
#'   dag_node("Demand","X") %>%
#'   dag_node("Price","Y", child = "X") %>%
#'   dag_render()
#'
#' # Hide the mathematical details of a graph
#' dag_create() %>%
#'   dag_node("Demand","X") %>%
#'   dag_node("Price","Y", child = "X") %>%
#'   dag_render(shortLabel = TRUE)
#' @importFrom dplyr select rename mutate filter left_join
#' @importFrom dplyr case_when as_tibble as_data_frame
#' @return Returns an object of class `grViz` and `htmlwidget` that is also rendered in the RStudio viewer for interactive buidling of graphical models.
#' @importFrom lifecycle badge
#' @export

dag_render <- function(graph,
                       shortLabel = FALSE,
                       wrapWidth = 24,
                       width = NULL,
                       height = NULL,
                       fillColor = "aliceblue",
                       fillColorObs = "cadetblue") {

  ## First validate that the first argument is indeed a causact_graph
  class_g <- class(graph)
  ## Any causact_graph will have class length of 1
  if(length(class_g) > 1){
    ## This specific case is hard-coded as it has occured often in early use by the author
    if(class_g[1] == chr("grViz") && class_g[2]=="htmlwidget"){
      errorMessage <- paste0("Given rendered Causact Graph. Check the declaration for a dag_render() call.")
    }
    else {
      errorMessage <- paste0("Cannot render given object as it is not a Causact Graph.")
    }
    stop(errorMessage)
  }
  ## Now check the single class
  if(class_g != "causact_graph"){
    errorMessage <- paste0("Cannot render given object as it is not a Causact Graph.")
    stop(errorMessage)
  }

  graph = graph
  sLabel = shortLabel
  ww = wrapWidth

  ## code to give output even if no nodes are added
  if (nrow(graph$nodes_df) == 0) {
    graph = graph %>% dag_node("START MODELLING", label = "use dag_node()")
  }

  dot_code = graph %>%
    dag_diagrammer(shortLabel = sLabel, wrapWidth = ww, fillColor = fillColor, fillColorObs = fillColorObs) %>%
    DiagrammeR::generate_dot()

  # Generate a `grViz` object
  grVizObject <-
    DiagrammeR::grViz(
      diagram = dot_code,
      width = width,
      height = height)

  display <- grVizObject

  display
}


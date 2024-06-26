% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/setWorkflowDefaults.R
\name{setDirectedGraphTheme}
\alias{setDirectedGraphTheme}
\title{Set DiagrammeR defaults for graphical models}
\usage{
setDirectedGraphTheme(
  dgrGraph,
  fillColor = "aliceblue",
  fillColorObs = "cadetblue"
)
}
\arguments{
\item{dgrGraph}{A DiagrammeR graph}

\item{fillColor}{Default R color for filling nodes.}

\item{fillColorObs}{R color for filling obeserved nodes.}
}
\value{
An updated version of \code{dgrGraph} with good defaults for
graphical models.

return a \code{dgrGraph} object with the color and shape defaults used by the \code{causact} package.
}
\description{
\code{setDirectedGraph} returns a graph with good defaults.
}
\examples{
library(DiagrammeR)
create_graph() \%>\% add_node() \%>\% render_graph()  # default DiagrammeR aesthetics
create_graph() \%>\% add_node() \%>\% setDirectedGraphTheme() \%>\% render_graph() ## causact aesthetics
}

% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ALE.R
\name{ALE}
\alias{ALE}
\title{Accumulated Local Effect Plot (ALE)}
\usage{
ALE(
  model,
  variable = NULL,
  data = NULL,
  K = 10,
  type = c("equidistant", "quantile"),
  plot = TRUE
)
}
\arguments{
\item{model}{a model created by \code{\link{dnn}}}

\item{variable}{variable as string for which the PDP should be done}

\item{data}{data on which ALE is performed on, if NULL training data will be used.}

\item{K}{number of neighborhoods original feature space gets divided into}

\item{type}{method on how the feature space is divided into neighborhoods.}

\item{plot}{plot ALE or not}
}
\value{
A list of plots made with 'ggplot2' consisting of an individual plot for each defined variable.
}
\description{
Performs an ALE for one or more features.
}
\details{
If the defined variable is a numeric feature, the ALE is performed.
Here, the non centered effect for feature j with k equally distant neighborhoods is defined as:

\eqn{ \hat{\tilde{f}}_{j,ALE}(x)=\sum_{k=1}^{k_j(x)}\frac{1}{n_j(k)}\sum_{i:x_{j}^{(i)}\in{}N_j(k)}\left[\hat{f}(z_{k,j},x^{(i)}_{\setminus{}j})-\hat{f}(z_{k-1,j},x^{(i)}_{\setminus{}j})\right]}

Where \eqn{N_j(k)} is the k-th neighborhood and \eqn{n_j(k)} is the number of observations in the k-th neighborhood.

The last part of the equation,
\eqn{\left[\hat{f}(z_{k,j},x^{(i)}_{\setminus{}j})-\hat{f}(z_{k-1,j},x^{(i)}_{\setminus{}j})\right]}
represents the difference in model prediction when the value of feature j is exchanged with the upper and lower border of the current neighborhood.
}
\examples{
\donttest{
if(torch::torch_is_installed()){
library(cito)

# Build and train  Network
nn.fit<- dnn(Sepal.Length~., data = datasets::iris)

ALE(nn.fit, variable = "Petal.Length")
}
}
}
\seealso{
\code{\link{PDP}}
}

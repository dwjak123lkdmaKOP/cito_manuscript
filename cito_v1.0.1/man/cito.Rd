% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cito.R
\docType{package}
\name{cito}
\alias{cito}
\title{'cito': Building and training neural networks}
\description{
Building and training custom neural networks in the typical R syntax. The 'torch' package is used for numerical calculations, which allows for training on CPU as well as on a graphics card.
The main function is \code{\link{dnn}} which trains a custom deep neural network.
}
\section{Installation}{


in order to install cito please follow these steps:

\code{install.packages("cito")}

\code{library(torch)}

\code{install_torch(reinstall = TRUE)}

\code{library(cito)}
}

\section{cito functions}{

\itemize{
\item \code{\link{dnn}}: train deep neural network
\item \code{\link{continue_training}}: continues training of an existing cito dnn model for additional epochs
\item \code{\link{PDP}}: plot the partial dependency plot for a specific feature
\item \code{\link{ALE}}: plot the accumulated local effect plot for a specific feature
}
}

\examples{
\donttest{
if(torch::torch_is_installed()){
library(cito)

set.seed(222)
validation_set<- sample(c(1:nrow(datasets::iris)),25)

# Build and train  Network
nn.fit<- dnn(Sepal.Length~., data = datasets::iris[-validation_set,])

# Sturcture of Neural Network
print(nn.fit)

# Use model on validation set
predictions <- predict(nn.fit, iris[validation_set,])

# Scatterplot
plot(iris[validation_set,]$Sepal.Length,predictions)
# MAE
mean(abs(predictions-iris[validation_set,]$Sepal.Length))

# Get variable importances
summary(nn.fit)

# Partial dependencies
PDP(nn.fit, variable = "Petal.Length")

# Accumulated local effect plots
ALE(nn.fit, variable = "Petal.Length")

# Custom loss functions and additional parameters
## Normal Likelihood with sd parameter:
custom_loss = function(true, pred) {
  logLik = torch::distr_normal(pred,
                               scale = torch::nnf_relu(scale)+
                                 0.001)$log_prob(true)
  return(-logLik$mean())
}

nn.fit<- dnn(Sepal.Length~.,
             data = datasets::iris[-validation_set,],
             loss = custom_loss,
             custom_parameters = list(scale = 1.0)
)
nn.fit$parameter$scale

## Multivariate normal likelihood with parametrized covariance matrix
## Sigma = L*L^t + D
## Helper function to build covariance matrix
create_cov = function(LU, Diag) {
  return(torch::torch_matmul(LU, LU$t()) + torch::torch_diag(Diag+0.01))
}

custom_loss_MVN = function(true, pred) {
  Sigma = create_cov(SigmaPar, SigmaDiag)
  logLik = torch::distr_multivariate_normal(pred,
                                            covariance_matrix = Sigma)$
    log_prob(true)
  return(-logLik$mean())
}


nn.fit<- dnn(cbind(Sepal.Length, Sepal.Width, Petal.Length)~.,
             data = datasets::iris[-validation_set,],
             lr = 0.01,
             loss = custom_loss_MVN,
             custom_parameters =
               list(SigmaDiag =  rep(1, 3),
                    SigmaPar = matrix(rnorm(6, sd = 0.001), 3, 2))
)
as.matrix(create_cov(nn.fit$loss$parameter$SigmaPar,
                     nn.fit$loss$parameter$SigmaDiag))

}
}
}

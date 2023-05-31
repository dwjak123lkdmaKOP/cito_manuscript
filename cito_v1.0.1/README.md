
# cito

<!-- badges: end -->

'cito' aims at helping you build and train Neural Networks with the standard R syntax. It allows the whole model creation process and training to be done with one line of code. Furthermore, all generic R methods such as print or  plot can be used on the created object. It is based on the 'torch' machine learning framework which is  available for R. Since it is native to R, no Python installation or any further API is needed for this package. 

## Installation
Before installing cito make sure torch is installed. See the code chunk below if you are unsure on how to check this 


``` r
#check package 
if(!require('torch',quietly = TRUE)) install.packages('torch')
library('torch') 

#install torch
if(!torch_is_installed()) install_torch()
```

```

## Example 
Once installed, the main function dnn() can be used. See the example below. A more in depth explanation can be found in the vignette.

``` r
library(cito)
validation_set <- sample(c(1:nrow(datasets::iris)),25)

# Build and train  Network
nn.fit <- dnn(Sepal.Length~., data = datasets::iris[-validation_set,])

# Analyze training 
analyze_training(nn.fit)

# Print sturcture of Neural Network
print(nn.fit)

# Plot Structure of Neural Network 
plot(nn.fit)

# continue training for another 32 epochs
nn.fit< - continue_training(nn.fit) 

# Use model on validation set
predictions <- predict(nn.fit, iris[validation_set,])

# Scatterplot
plot(iris[validation_set,]$Sepal.Length,predictions)
# MAE
mean(abs(predictions-iris[validation_set,]$Sepal.Length))
``` 

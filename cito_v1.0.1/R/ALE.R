#' Accumulated Local Effect Plot (ALE)
#'
#'
#' Performs an ALE for one or more features.
#'
#' @details
#'
#' If the defined variable is a numeric feature, the ALE is performed.
#' Here, the non centered effect for feature j with k equally distant neighborhoods is defined as:
#'
#' \eqn{ \hat{\tilde{f}}_{j,ALE}(x)=\sum_{k=1}^{k_j(x)}\frac{1}{n_j(k)}\sum_{i:x_{j}^{(i)}\in{}N_j(k)}\left[\hat{f}(z_{k,j},x^{(i)}_{\setminus{}j})-\hat{f}(z_{k-1,j},x^{(i)}_{\setminus{}j})\right]}
#'
#' Where \eqn{N_j(k)} is the k-th neighborhood and \eqn{n_j(k)} is the number of observations in the k-th neighborhood.
#'
#' The last part of the equation,
#' \eqn{\left[\hat{f}(z_{k,j},x^{(i)}_{\setminus{}j})-\hat{f}(z_{k-1,j},x^{(i)}_{\setminus{}j})\right]}
#' represents the difference in model prediction when the value of feature j is exchanged with the upper and lower border of the current neighborhood.
#' @param model a model created by \code{\link{dnn}}
#' @param variable variable as string for which the PDP should be done
#' @param data data on which ALE is performed on, if NULL training data will be used.
#' @param K number of neighborhoods original feature space gets divided into
#' @param type method on how the feature space is divided into neighborhoods.
#' @param plot plot ALE or not
#' @seealso \code{\link{PDP}}
#' @return A list of plots made with 'ggplot2' consisting of an individual plot for each defined variable.
#' @example /inst/examples/ALE-example.R
#' @export

ALE <- function(model,
                variable = NULL,
                data = NULL,
                K = 10,
                type = c("equidistant", "quantile"),
                plot=TRUE){
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop(
      "Package \"ggplot2\" must be installed to use this function.",
      call. = FALSE
    )
  }
  model <- check_model(model)
  type <- match.arg(type)
  if(is.null(data)){
    data <- model$data$data
  }
  if(is.null(variable)) variable <- get_var_names(model$training_properties$formula, data[1,])
  if(!any(variable %in% get_var_names(model$training_properties$formula, data[1,]))){
    warning("unknown variable")
    return(NULL)
  }

  x <- NULL
  y <- NULL

  is_categorical = sapply(data[, variable], is.factor )

  if(any(is_categorical)) {
    cat("Categorical features are not yet supported.\n")
    variable = variable[!is_categorical]
  }


  p_ret <- sapply (variable,function(v){
      results =
            lapply(1:model$model_properties$output, function(n_output) {

            if ( type == "equidistant"){
              reduced_K <- FALSE
              repeat{
                borders <- seq(from = min(data[,v]),
                               to = max(data[,v]),
                               length.out = K+1)

                df <- data.frame(
                  x = borders[1:K] + ((borders[2]-borders[1])/2),

                  y = sapply(seq_len(length(borders))[-1], function(i){

                    region_indizes <- which(data[,v]<= borders[i] &
                                              data[,v]>= borders[i-1])

                    if(length(region_indizes)>0){
                      perm_data <- data[region_indizes,]

                      perm_data[,v] <- borders[i-1]
                      lower_preds <- stats::predict(model, perm_data)[,n_output,drop=FALSE]

                      perm_data[,v] <- borders[i]
                      upper_preds <- stats::predict(model, perm_data)[,n_output,drop=FALSE]

                      return(mean(upper_preds - lower_preds))
                    }else{

                      return(NA)

                    }
                  })
                )

                if(any(is.na(df$y))){
                  reduced_K <- TRUE
                  K <- K - 1
                }else{
                  if(reduced_K){
                    message(paste0("Number of Neighborhoods reduced to ",K))
                  }
                  break
                }
              }
            }else if ( type == "quantile"){

              quants <- stats::quantile(data[,v],probs = seq(0,1,1/K))
              groups <- lapply(c(2:(K+1)),function(i) return(which(data[,v] >= quants[i-1] & data[,v] < quants[i])))
              groups[[length(groups)]] <- c(groups[[length(groups)]],which.max(data[,v]))


              df <- data.frame (
                x = unlist(lapply(c(2:(K+1)), function(i)  return(unname((quants[i]+quants[i-1])/2)))),
                y = unlist(lapply(seq_len(length(groups)), function(i){

                  perm_data <- data[groups[[i]],]

                  perm_data[,v] <- quants[i]
                  lower_preds <- stats::predict(model, perm_data)[,n_output,drop=FALSE]

                  perm_data[,v] <- quants[i+1]
                  upper_preds <- stats::predict(model, perm_data)[,n_output,drop=FALSE]

                  return(mean(upper_preds - lower_preds))
                  })))




            }
            for ( i in seq_len(nrow(df))[-1]){
              df$y[i]<- df$y[i-1]+df$y[i]
            }

            df$y <- df$y - mean(df$y)

            if(!is.null(model$data$ylvls)) {
              label = paste0("ALE - ", model$data$ylvls[n_output])
            } else {
              label = "ALE"
            }

            p <- ggplot2::ggplot(data=df, mapping = ggplot2::aes(x = x,y = y))
            p <- p + ggplot2::geom_line()
            p <- p + ggplot2::ggtitle(label = label)
            p <- p + ggplot2::xlab(label = v)
            p <- p + ggplot2::ylab(label = "ALE")
            geom_df<- data.frame(x = data[,v])
            p <- p + ggplot2::geom_rug(sides="b", data = geom_df,
                                       mapping = ggplot2::aes(x = x),
                                       inherit.aes = FALSE)
            p <- p + ggplot2::theme_bw()

            return(p)
        })

      results[sapply(results, is.null)] = NULL

      return(results)
    })

  p_ret = do.call(list, p_ret)
  if(plot) {
    if(model$model_properties$output >1) do.call(gridExtra::grid.arrange, c(p_ret, nrow = ceiling(length(p_ret)/model$model_properties$output)))
    else do.call(gridExtra::grid.arrange, c(p_ret, ncol = length(p_ret)))
  }

  if(!is.null(model$data$ylvls)) {
    names(p_ret) = paste0(model$data$ylvls, "_",names(p_ret))
  }
  return(invisible(p_ret))
}


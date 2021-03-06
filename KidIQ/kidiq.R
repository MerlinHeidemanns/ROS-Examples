#' ---
#' title: "Regression and Other Stories: KidIQ"
#' author: "Andrew Gelman, Jennifer Hill, Aki Vehtari"
#' date: "`r format(Sys.Date())`"
#' output:
#'   html_document:
#'     theme: readable
#'     toc: true
#'     toc_depth: 2
#'     toc_float: true
#'     code_download: true
#' ---

#' Linear regression with multiple predictors. See Chapters 10, 11 and
#' 12 in Regression and Other Stories.
#' 
#' -------------
#' 

#+ setup, include=FALSE
knitr::opts_chunk$set(message=FALSE, error=FALSE, warning=FALSE, comment=NA)
# switch this to TRUE to save figures in separate files
savefigs <- FALSE

#' #### Load packages
library("rprojroot")
root<-has_file(".ROS-Examples-root")$make_fix_file()
library("rstanarm")
library("ggplot2")
library("bayesplot")
theme_set(bayesplot::theme_default(base_family = "sans"))
library("foreign")

#' #### Load children's test scores data
kidiq <- read.csv(root("KidIQ/data","kidiq.csv"))
head(kidiq)

#' ## A single predictor
#' 

#' #### A single binary predictor 
#' 
#' The option `refresh = 0` supresses the default Stan sampling
#' progress output. This is useful for small data with fast
#' computation. For more complex models and bigger data, it can be
#' useful to see the progress.
fit_1 <- stan_glm(kid_score ~ mom_hs, data=kidiq, refresh = 0)
print(fit_1)

#' #### A single continuous predictor 
fit_2 <- stan_glm(kid_score ~ mom_iq, data=kidiq, refresh = 0)
print(fit_2)

#' #### Displaying a regression line as a function of one input variable
plot(kidiq$mom_iq, kidiq$kid_score, xlab="Mother IQ score", ylab="Child test score")
abline(coef(fit_2))
# or
#abline(coef(fit_2)[1], coef(fit_2)[2])
# or
#curve(cbind(1,x) %*% coef(fit_2), add=TRUE)

#' #### ggplot version
ggplot(kidiq, aes(mom_iq, kid_score)) +
  geom_point() +
  geom_abline(intercept = coef(fit_2)[1], slope = coef(fit_2)[2]) +
  labs(x = "Mother IQ score", y = "Child test score")

#' ## Two predictors
#' 

#' #### Linear regression
fit_3 <- stan_glm(kid_score ~ mom_hs + mom_iq, data=kidiq, refresh = 0)
print(fit_3)

#' #### Alternative display
summary(fit_3)

#' ### Graphical displays of data and fitted models
#' 

#' #### Two fitted regression lines -- model with no interaction
colors <- ifelse(kidiq$mom_hs==1, "black", "gray")
plot(kidiq$mom_iq, kidiq$kid_score,
  xlab="Mother IQ score", ylab="Child test score", col=colors, pch=20)
b_hat <- coef(fit_3)
abline(b_hat[1] + b_hat[2], b_hat[3], col="black")
abline(b_hat[1], b_hat[3], col="gray")

#' #### ggplot version
ggplot(kidiq, aes(mom_iq, kid_score)) +
  geom_point(aes(color = factor(mom_hs)), show.legend = FALSE) +
  geom_abline(
    intercept = c(coef(fit_3)[1], coef(fit_3)[1] + coef(fit_3)[2]),
    slope = coef(fit_3)[3],
    color = c("gray", "black")) +
  scale_color_manual(values = c("gray", "black")) +
  labs(x = "Mother IQ score", y = "Child test score")

#' #### Two fitted regression lines -- model with interaction
fit_4 <- stan_glm(kid_score ~ mom_hs + mom_iq + mom_hs:mom_iq, data=kidiq,
                  refresh = 0)
print(fit_4)
colors <- ifelse(kidiq$mom_hs==1, "black", "gray")
plot(kidiq$mom_iq, kidiq$kid_score,
  xlab="Mother IQ score", ylab="Child test score", col=colors, pch=20)
b_hat <- coef(fit_4)
abline(b_hat[1] + b_hat[2], b_hat[3] + b_hat[4], col="black")
abline(b_hat[1], b_hat[3], col="gray")

#' #### ggplot version
ggplot(kidiq, aes(mom_iq, kid_score)) +
  geom_point(aes(color = factor(mom_hs)), show.legend = FALSE) +
  geom_abline(
    intercept = c(coef(fit_4)[1], sum(coef(fit_4)[1:2])),
    slope = c(coef(fit_4)[3], sum(coef(fit_4)[3:4])),
    color = c("gray", "black")) +
  scale_color_manual(values = c("gray", "black")) +
  labs(x = "Mother IQ score", y = "Child test score")

#' ## Displaying uncertainty in the fitted regression
#' 

#' #### A single continuous predictor 
print(fit_2)
sims_2 <- as.matrix(fit_2)
n_sims_2 <- nrow(sims_2)
subset <- sample(n_sims_2, 10)
plot(kidiq$mom_iq, kidiq$kid_score,
     xlab="Mother IQ score", ylab="Child test score")
for (i in subset){
  abline(sims_2[i,1], sims_2[i,2], col="gray")
}
abline(coef(fit_2)[1], coef(fit_2)[2], col="black")

#' ggplot version
ggplot(kidiq, aes(mom_iq, kid_score)) +
  geom_point() +
  geom_abline(
    intercept = sims_2[subset, 1],
    slope = sims_2[subset, 2],
    color = "gray",
    size = 0.25) +
  geom_abline(
    intercept = coef(fit_2)[1],
    slope = coef(fit_2)[2],
    size = 0.75) +
  labs(x = "Mother IQ score", y = "Child test score")

#' #### Two predictors 
sims_3 <- as.matrix(fit_3)
n_sims_3 <- nrow(sims_3)

#+ eval=FALSE, include=FALSE
if (savefigs) pdf(root("KidIQ/figs","kidiq.betasim2.pdf"), height=3.5, width=9)
#+
par(mar=c(3,3,1,3), mgp=c(1.7, .5, 0), tck=-.01)
par(mfrow=c(1,2))
plot(kidiq$mom_iq, kidiq$kid_score, xlab="Mother IQ score", ylab="Child test score", bty="l", pch=20, xaxt="n", yaxt="n")
axis(1, seq(80, 140, 20))
axis(2, seq(20, 140, 40))
mom_hs_bar <- mean(kidiq$mom_hs)
subset <- sample(n_sims_3, 10)
for (i in subset){
  curve(cbind(1, mom_hs_bar, x) %*% sims_3[i,1:3], lwd=.5,
     col="gray", add=TRUE)
}
curve(cbind(1, mom_hs_bar, x) %*% coef(fit_3), col="black", add=TRUE)
jitt <- runif(nrow(kidiq), -.03, .03)
plot(kidiq$mom_hs + jitt, kidiq$kid_score, xlab="Mother completed high school", ylab="Child test score", bty="l", pch=20, xaxt="n", yaxt="n")
axis(1, c(0,1))
axis(2, seq(20, 140, 40))
mom_iq_bar <- mean(kidiq$mom_iq)
for (i in subset){
  curve(cbind(1, x, mom_iq_bar) %*% sims_3[i,1:3], lwd=.5,
     col="gray", add=TRUE)
}
curve(cbind(1, x, mom_iq_bar) %*% coef(fit_3), col="black", add=TRUE)
#+ eval=FALSE, include=FALSE
if (savefigs) dev.off()

#' #### Center predictors to have zero mean
kidiq$c_mom_hs <- kidiq$mom_hs - mean(kidiq$mom_hs)
kidiq$c_mom_iq <- kidiq$mom_iq - mean(kidiq$mom_iq)
fit_4c <- stan_glm(kid_score ~ c_mom_hs + c_mom_iq + c_mom_hs:c_mom_iq,
                   data=kidiq, refresh = 0)
print(fit_4c)

#' #### Center predictors based on a reference point
kidiq$c2_mom_hs <- kidiq$mom_hs - 0.5
kidiq$c2_mom_iq <- kidiq$mom_iq - 100
fit_4c2 <- stan_glm(kid_score ~ c2_mom_hs + c2_mom_iq + c2_mom_hs:c2_mom_iq,
                    data=kidiq, refresh = 0)
print(fit_4c2)

#' #### Center and scale predictors to have zero mean and sd=1/2
kidiq$z_mom_hs <- (kidiq$mom_hs - mean(kidiq$mom_hs))/(2*sd(kidiq$mom_hs))
kidiq$z_mom_iq <- (kidiq$mom_iq - mean(kidiq$mom_iq))/(2*sd(kidiq$mom_iq))
fit_4z <- stan_glm(kid_score ~ z_mom_hs + z_mom_iq + z_mom_hs:z_mom_iq,
                   data=kidiq, refresh = 0)
print(fit_4z)

#' #### Predict using working status of mother
fit_5 <- stan_glm(kid_score ~ as.factor(mom_work), data=kidiq, refresh = 0)
print(fit_5)

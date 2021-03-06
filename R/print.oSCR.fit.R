print.oSCR.fit <- function(x, burn=NULL, ...){
  if("parameters" %in% names(x$outStats)){
    if("model" %in% names(x$call)){
      mod <- x$call[["model"]]
    }else{
      mod <- list(D~1,p0~1,sig~1,asu~1)
    }
    if(is.factor(x$outStats[,2])){
      tmpFit <- cbind(x$outStats[,3],
                      x$outStats[,4],
                      x$outStats[,3]/x$outStats[,4],
                      2*(1 - pnorm(abs(x$outStats[,3]/x$outStats[,4]))))
      
    }else{  
      tmpFit <- cbind(x$outStats[,2],
                      x$outStats[,3],
                      x$outStats[,2]/x$outStats[,3],
                      2*(1 - pnorm(abs(x$outStats[,2]/x$outStats[,3]))))
    }
    ord <- c(grep("p0.",x$outStats$parameters),
             grep("t.beta",x$outStats$parameters),
             grep("p.behav",x$outStats$parameters),
             grep("sig.",x$outStats$parameters),
             grep("d0.",x$outStats$parameters),
             grep("d.beta",x$outStats$parameters),
             grep("c0.",x$outStats$parameters),
             grep("c.beta",x$outStats$parameters),
             grep("psi",x$outStats$parameters))
    rownames(tmpFit) <- x$outStats[,1]
    colnames(tmpFit) <-c("Estimate","SE","z","P(>|z|)")
    cat(" Model: ", paste(mod)[-1],fill=TRUE)
    cat(" Run time: ", x$proctime," minutes",fill=TRUE)
    cat(" AIC: ", x$AIC,fill=TRUE)
    cat(" ",fill=TRUE)
    cat("Summary table:","\n")
    print(round(tmpFit[ord,],3))
    cat("*Density intercept is log(individuals per pixel)","\n")
    cat("  Nhat(state-space) = exp(d0.)*nrow(ssDF)", fill=TRUE)
    cat("  (caution is warranted when model contains density covariates)",fill=TRUE)  
  }else{
    if("model" %in% names(x$call)){
      mod <- x$call[["model"]]
    }else{
      mod <- list(D~1,p0~1,sig~1,asu~1)
    }
    tmpFit <- x$outStats
    cat(" Model: ", paste(mod)[-1],fill=TRUE)
    cat(" Run time: ", x$proctime," minutes",fill=TRUE)
    cat(" AIC: ", x$AIC,fill=TRUE)
    cat(" ",fill=TRUE)
    cat("Summary table:","\n")
    print(round(tmpFit,3))
    cat("*Density is per pixel density","\n")
  }
}

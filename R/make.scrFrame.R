make.scrFrame <- function(caphist, traps, indCovs=NULL, trapCovs=NULL, sigCovs=NULL,
                          trapOperation=NULL, telemetry=NULL, rsfDF=NULL, type="scr"){

  #must have caphist and traps
  if(any(is.null(caphist),is.null(traps)))
    stop("caphist and trap must be provided")

  #caphist
  if(!is.list(caphist))
    stop("caphist must be a list")
  n.sessions <- length(caphist)
  caphist.dimensions <- sapply(caphist,dim)

  if(nrow(caphist.dimensions)==2)
    caphist.dimensions <- rbind(caphist.dimensions,1)

  for(i in 1:n.sessions){
    caphist[[i]] <- array(caphist[[i]], dim=caphist.dimensions[,i])
    all.zero <- apply(apply(caphist[[i]],c(1,3),sum),1,sum)
    if(any(all.zero==0)){
      cat("At least one individual has an all-zero encounter history", fill=TRUE)
      cat("Make sure this is ok...",fill=TRUE)
  }
  }

  #indCovs
  if(!is.null(indCovs)){
    if(!is.list(indCovs))
      stop("indCovs must be a list")
    if(any(!sapply(indCovs,is.data.frame)))
      stop("indCovs must be a list of dataframes")
    if(length(indCovs) != length(caphist))
      stop("number of sessions in indCovs does not match caphist")

    check.dim <- sapply(indCovs,nrow)
    if(any(check.dim!=caphist.dimensions[1,]))
      stop("number of individuals in indCovs does not match caphist")
    if(!("rmv" %in% indCovs[[1]])){
      for(i in 1:length(indCovs)){
        indCovs[[i]]$removed <- dim(caphist[[i]])[3]
      }
    }
  }else{
    indCovs <- list()
    for(i in 1:length(caphist)){
      indCovs[[i]] <- data.frame(removed = rep(dim(caphist[[i]])[3],dim(caphist[[i]])[1]))
    }
  }

  #traps
  if(!is.list(traps))
    stop("traps must be a list")
  #if(any(!sapply(traps,is.data.frame)))
  #  stop("traps must be a list of dataframes")
  if(length(traps)!=length(caphist))
    stop("number of sessions in traps does not match caphist")

  check.dim <- sapply(traps,nrow)
  if(!all(check.dim==caphist.dimensions[2,]))
    stop("number of traps does not match caphist")

  #trapCovs
  if(!is.null(trapCovs)){
    if(!is.list(trapCovs))
      stop("trapCovs must be a list")
    if(any(!sapply(trapCovs,is.list)))
      stop("trapCovs must be a list of lists")
    if(any(!unlist(sapply(trapCovs,function(x)sapply(x,is.data.frame)))))
      stop("trapCovs must be a list of dataframes")
    if(length(trapCovs) != length(caphist))
      stop("number of sessions in trapCovs does not match caphist")
    #check.dim <- sapply(trapCovs,function(x)sapply(x,nrow))
    check.dim <- lapply(trapCovs,function(x)sapply(x,nrow))
    for(i in 1:length(check.dim)){
      if(!all(check.dim[[i]]==caphist.dimensions[2,i]))
        stop("number of traps does not match caphist")
    }
  }

  #sigCovs
  if(!is.null(sigCovs)){
    if(nrow(sigCovs) != length(caphist))
      stop("number of rows in sigCovs does not match number of sessions")
    if(!"session" %in% colnames(sigCovs)){
      sigCovs$session <- factor(1:n.sessions)
    }
    if(!is.null(indCovs)){
      if("sex" %in% colnames(indCovs[[1]])){
        sigCovs <- sigCovs[rep(1:n.sessions,2),,drop=F]
        rownames(sigCovs) <- NULL
        sigCovs$sex <- factor(rep(c("female","male"),each=n.sessions))
      }
    }
  }else{
    sigCovs <- data.frame(session = factor(1:n.sessions))
    if(!is.null(indCovs)){
      if("sex" %in% colnames(indCovs[[1]])){
        sigCovs <- sigCovs[rep(1:n.sessions,2),,drop=F]
        rownames(sigCovs) <- NULL
        sigCovs <- sigCovs[rep(1:n.sessions,2),,drop=F]
        rownames(sigCovs) <- NULL
        sigCovs$sex <- factor(rep(c("female","male"),each=n.sessions))
      }
    }
  }

  #trapOperation
  if(!is.null(trapOperation)){
    if(!is.list(trapOperation))
      stop("trapOperation must be a list")
    #if(any(!sapply(trapOperation,is.data.frame)))
    #  stop("trapOperation must be a list of dataframes")
    if(length(trapOperation) != length(caphist))
      stop("number of sessions in trapOperation does not match caphist")
    check.dim <- sapply(trapOperation,nrow)
    if(!all(check.dim==caphist.dimensions[2,]))
      stop("number of traps does not match caphist")
  }

  #mean maximum distance moved
  max.dist <- NULL
  for (i in 1:length(caphist)) {
    for (j in 1:nrow(caphist[[i]])){
      if(dim(caphist[[i]])[3]>1){
        where <- apply(caphist[[i]][j, , ], 1, sum) > 0
      }else{
        where <- caphist[[i]][j, , ] > 0
      }
      if (sum(where) > 1)
        max.dist <- c(max.dist, max(0, dist(traps[[i]][where, c("X", "Y")]), na.rm = T))
    }
  }
  l1 <- length(max.dist)
  l2 <- length(max.dist[max.dist > 0])
  if(l1==0 | l2==0){
    mmdm <- 0
    mdm <- 0
  }else{
    mmdm <- mean(max.dist[max.dist > 0], na.rm = T)
    mdm <- max(max.dist,na.rm=T)
  }
  

  #telemetry
  if(!is.null(telemetry)){

    #fixfreq
    if(!is.list(telemetry$fixfreq))
      stop("telemetry$fixfreq must be a list")
    fixfreq.dimensions <- sapply(telemetry$fixfreq,dim)

    if(nrow(fixfreq.dimensions)==2)
      fixfreq.dimensions <- rbind(fixfreq.dimensions,1)

    #indCovs for telemetry
    if(!is.null(telemetry$indCovs)){
      if(!is.list(telemetry$indCovs))
        stop("telemetry$indCovs must be a list")
      if(any(!sapply(telemetry$indCovs,is.data.frame)))
        stop("telemetry$indCovs must be a list of dataframes")
      if(length(telemetry$indCovs) != length(telemetry$fixfreq))
        stop("number of sessions in telemetry$indCovs does not match telemetry$fixfreq")

      check.dim <- sapply(telemetry$indCovs,nrow)
      if(any(check.dim!=fixfreq.dimensions[1,]))
        stop("number of individuals in telemetry$indCovs does not match telemetry$fixfreq")
      if(any(!names(indCovs[[1]]) %in% c(names(telemetry$indCovs[[1]]),"removed")))
        stop("indCovs do not match between capture and telemetry data")
    }
    #overlap between collared/captured individuals
    if(!is.null(telemetry$cap.tel)){
      if(!is.list(telemetry$cap.tel))
        stop("telemetry$indCovs must be a list")
      warning("make sure captured individuals w/ collars sorted first!")
    }

  }
    if(!is.null(rsfDF)){
      library(FNN)
      rsfCovs <- names(rsfDF[[1]][,-c(1:2),drop=F])

      if(is.null(trapCovs)){
        trapCovs <- list(); length(trapCovs) <- n.sessions
        for(s in 1:n.sessions){
          trap.grid <- as.vector(get.knnx(rsfDF[[s]][,c("X","Y")],traps[[s]][,c("X","Y")],1)$nn.index)
          trapCovs[[s]] <- list(); length(trapCovs[[s]]) <- caphist.dimensions[3,s]
          for (k in 1:caphist.dimensions[3,s]){
            trapCovs[[s]][[k]] <- data.frame(rsfDF[[s]][trap.grid,rsfCovs])
            names(trapCovs[[s]][[k]]) <- rsfCovs
          }
        }
      } else {
        for(s in 1:n.sessions){
          if(any(!rsfCovs %in% trapCovs[[s]][[1]])){
            miss.rsfCovs <- rsfCovs[which(!rsfCovs %in% trapCovs[[s]][[1]])]
            trap.grid <- as.vector(get.knnx(rsfDF[[s]][,c("X","Y")],traps[[s]][,c("X","Y")],1)$nn.index)
            for (k in 1:caphist.dimensions[3,s]){
              newtrapCovs <- data.frame(rsfDF[[s]][trap.grid,miss.rsfCovs])
              names(newtrapCovs) <- miss.rsfCovs
              trapCovs[[s]][[k]] <- data.frame(trapCovs[[s]][[k]],newtrapCovs)

            }
          }
        }
      }
    }


  scrFrame <- list("caphist" = caphist,
                   "traps" = traps,
                   "indCovs" = indCovs,
                   "trapCovs" = trapCovs,
                   "sigCovs" = sigCovs,
                   "trapOperation" = trapOperation,
                   "occasions" = caphist.dimensions[3,],
                   "type" = type,
                   "mmdm" = mmdm,
                   "mdm" = mdm,
                   "telemetry" = telemetry)

  class(scrFrame) <- "scrFrame"
  return(scrFrame)
}

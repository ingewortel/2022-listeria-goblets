library( celltrackR )


# Getting the Acov data of a set of tracks
getAcov <- function( tracks, FUN = "mean.se", norm = FALSE ){

	# compute Acov
	acovData <- aggregate( tracks, overallDot, FUN = FUN )
	if(norm) acovData[,2:4] <- acovData[,2:4]/acovData[1,2]

	# Scale time axis: by default, this is in number of steps; convert to seconds.
	tau <- timeStep( tracks )  # in seconds
	acovData$dt <- (acovData$i-1) * tau
	
	# consistent output: also without confidence interval return 'mean' rather than 'value'
	if( any( colnames(acovData) == "value" ) ){
	index <- which( colnames( acovData ) == "value" )
	colnames(acovData)[index] <- "mean"
	}


	# For each delta_t, get the number of independent tracks the square displacements
	# were derived from. This is simply the number of tracks with a length of at least 
	# the current number of steps (i).
	trackSteps <- sapply( tracks, nrow ) - 1
	acovData$nCells <- sapply( acovData$i, function(x) sum( trackSteps >= x ) )
	acovData$fCells <- acovData$nCells / acovData$nCells[1] # fraction of tracks left
	return( acovData )
	
}

# Getting the turning angle data
getAngles <- function( tracks, FUN = "mean.se" ){

	# compute Acov
	angData <- aggregate( tracks, function(x){ overallAngle(x, degrees = TRUE)}, FUN = FUN, na.rm = TRUE )

	# Scale time axis: by default, this is in number of steps; convert to seconds.
	tau <- timeStep( tracks )  # in seconds
	angData$dt <- (angData$i-1) * tau
	
	# consistent output: also without confidence interval return 'mean' rather than 'value'
	if( any( colnames(angData) == "value" ) ){
	index <- which( colnames( angData ) == "value" )
	colnames(angData)[index] <- "mean"
	}


	# For each delta_t, get the number of independent tracks the square displacements
	# were derived from. This is simply the number of tracks with a length of at least 
	# the current number of steps (i).
	trackSteps <- sapply( tracks, nrow ) - 1
	angData$nCells <- sapply( angData$i, function(x) sum( trackSteps >= x ) )
	angData$fCells <- angData$nCells / angData$nCells[1] # fraction of tracks left
	return( angData )
	
}

# To fit an exponential decay on a given autocovariance dataset, returning the fitted tau
fitAcov <- function( acovData, start = list( A = acovData$mean[1]/2, tau = 0.5 ), lower = list( A = 0.001, tau = 0.01 ), cutoff = NULL ){

	# The bigger delta_t (or i, in number of steps) gets, the fewer independent tracks
	# the curve will be based on. Fit the curve only on the first part, where the number
	# of independent tracks is at least half the total number of tracks - or if a cutoff 
	# time delta_t is given, use that. Filter these points out here:
	if( !is.null( cutoff ) ){
		acovData <- acovData[ acovData$dt <= cutoff, ]
	} else {
		acovData <- acovData[ acovData$nCells >= (acovData$nCells[1]*0.60),  ]
	}
	

	# Fit this function using nls. Provide reasonable starting
	# values or the fitting algorithm will not work properly. 
	model <- nls( mean ~ A*exp( -dt/tau ), 
				  data = acovData, 
				  start = start, 
				  lower = lower, 
				  algorithm = "port" 
	)
	tau <- coefficients(model)[["tau"]]
	A <- coefficients(model)[["A"]]
	return( data.frame( tau = tau, A = A ) )

}

plotAcovFit <- function( acovData, fittedParms, cutoff = NULL, plotFit = TRUE ){
	require(rlang)
	require( ggplot2)
	if( !is.null( cutoff ) ){
		acovData <- acovData[ acovData$dt <= cutoff, ]
	} else {
		acovData <- acovData[ acovData$nCells >= (acovData$nCells[1]*0.60),  ]
	}
	A <- fittedParms$A[1]
	dtFit <- c(0,acovData$dt)
	acovFit <- data.frame( dt = dtFit, mean = A*exp( -dtFit/fittedParms$tau[1] ) )
	if( !plotFit ) v <- acovFit[ -seq(1,nrow(acovFit)), ]
	
	tau <- ifelse( is.na(fittedParms$tau[1]), -1, fittedParms$tau[1])
		
	p <- ggplot( acovData, aes( x = dt, y = mean ) ) +
		geom_hline( size = 0.3, yintercept = 0 ) +
		geom_vline( xintercept = tau, size = 0.3, lty = 2, color = "red"  ) +
		geom_line( size = 0.3, color = "gray70" ) +
		geom_line( data = acovFit, color = "red" ) +
		geom_point( size = 1 ) +
		scale_x_continuous( limits = c(0,NA)) +
		scale_y_continuous( limits=c(-1,11), breaks=seq(0,10,by=5)) +
		labs( x = expression( Delta*"t (s)"), y =expression("autocovariance ("*mu*"m"^2*")"))
		
	if( plotFit ){
		suppressWarnings({
			Tvalue <- as.character( round( fittedParms$tau[1], 2 ) )
			Tstring <- rlang::expr( "P = "* !!Tvalue* " s")

	
			p <- p + annotate( "text", x = 5, y = 10.5, #0.95*max( acovFit$mean), 
				label = Tstring, hjust = 1, size = 6*(5/14) ) 
		})
		
	}
	return(p)
}


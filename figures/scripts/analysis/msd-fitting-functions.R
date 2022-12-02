library( celltrackR )

# Furth's equation for the MSD
fuerthMSD <- function( dt, D, P, dim ){
  return( 2*dim*D*( dt - P*(1-exp(-dt/P) ) ) )
}

# Getting the MSD data of a set of tracks
getMSD <- function( tracks, FUN = "mean.se", ... ){

	# compute MSD
	msdData <- aggregate( tracks, squareDisplacement, subtrack.length = seq(0, (maxTrackLength(tracks) - 1)), FUN = FUN, ... )

	# Scale time axis: by default, this is in number of steps; convert to seconds.
	tau <- timeStep( tracks )  # in seconds
	msdData$dt <- msdData$i * tau
	
	# consistent output: also without confidence interval return 'mean' rather than 'value'
	if( any( colnames(msdData) == "value" ) ){
	index <- which( colnames( msdData ) == "value" )
	colnames(msdData)[index] <- "mean"
	}


	# For each delta_t, get the number of independent tracks the square displacements
	# were derived from. This is simply the number of tracks with a length of at least 
	# the current number of steps (i).
	trackSteps <- sapply( tracks, nrow ) - 1
	msdData$nCells <- sapply( msdData$i, function(x) sum( trackSteps >= x ) )
	msdData$fCells <- msdData$nCells / msdData$nCells[1] # fraction of tracks left
	return( msdData )
	
}

# To fit Furth's equation on a given MSD dataset, returning the fitted D and P
fitMSD <- function( msdData, dim = 2, start = list( D = 10, P = 0.005 ), lower = list( D = 0, P = 0.001 ), upper = list( D = Inf, P = Inf ), cutoff = NULL ){

	# The bigger delta_t (or i, in number of steps) gets, the fewer independent tracks
	# the MSD will be based on. Fit the curve only on the first part, where the number
	# of independent tracks is at least half the total number of tracks - or if a cutoff 
	# time delta_t is given, use that. Filter these points out here:
	if( !is.null( cutoff ) ){
		msdData <- msdData[ msdData$dt <= cutoff, ]
	} else {
		msdData <- msdData[ msdData$nCells >= (msdData$nCells[1]*0.60),  ]
	}
	

	# Fit this function using nls. Provide reasonable starting
	# values or the fitting algorithm will not work properly. 
	model <- nls( mean ~ fuerthMSD( dt, D, P, dim = dim ), 
				  data = msdData, 
				  start = start, 
				  lower = lower, 
				  upper = upper,
				  algorithm = "port" 
	)
	D <- coefficients(model)[["D"]] 
	P <- coefficients(model)[["P"]] 
	return( data.frame( D = D, P = P ) )

}

plotMSDfit <- function( msdData, fittedParms, cutoff = NULL, furth = TRUE ){
	require(rlang)
	if( !is.null( cutoff ) ){
		msdData <- msdData[ msdData$dt <= cutoff, ]
	} else {
		msdData <- msdData[ msdData$nCells >= (msdData$nCells[1]*0.60),  ]
	}

	msdFurth <- data.frame( dt = msdData$dt, mean = fuerthMSD( msdData$dt, fittedParms$D[1], fittedParms$P[1], dim = 2 ) )
	if( !furth ) msdFurth <- msdFurth[ -seq(1,nrow(msdFurth)), ]
	
	p <- ggplot( msdData, aes( x = dt, y = mean ) ) + 
		geom_vline( xintercept = fittedParms$P[1], size = 0.3, lty = 2, color = "red"  ) +
		geom_line( data = msdFurth, color = "red" ) +
		geom_point( size = 1 ) +
		scale_x_continuous( limits = c(0,NA)) +
		scale_y_continuous( limits=c(0,NA)) +
		labs( x = expression( Delta*"t (s)"), y = expression( "MSD ("*mu*"m"^2*")"))
		
	if( furth ){
		Dvalue <- as.character( round( fittedParms$D[1], 2 ) )
		Dstring <- rlang::expr( "M = "* !!Dvalue* " "* mu*"m"^2*"/s")
		Pvalue <- as.character( round( fittedParms$P[1], 2 ) )
		Pstring <- rlang::expr( "P = "* !!Pvalue* " s")
	
		p <- p + annotate( "text", x = 5, y = 0.15*max(msdFurth$mean),
			label = Dstring, hjust = 1, size = 6*(5/14) ) +
			annotate( "text", x = 5, y = 0, 
				label = Pstring, hjust = 1, vjust = 0, size = 6*(5/14) )
	}
	return(p)
}


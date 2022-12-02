# This script reads an input csv file and saves tracks as an R .rds object.

library( celltrackR )
library( mvtnorm )

argv <- commandArgs( trailingOnly = TRUE )

csvFile <- argv[1]
outFile <- argv[2]

phagocyteData <- read.tracks.csv( csvFile, 
                                  id.column = 8, time.column = 7, pos.columns=1:3, 
                                  sep = ",", scale.t = 25 )
                                  
                                  # project xy plane
phagocyteData <- projectDimensions( phagocyteData )


# Null-model: cell does not move.
# For a non-moving cell, we assume that the track coordinates are in a bivariate Gaussian
# of sd = sigma around the track starting point (just due to measurement noise).
# Compute BIC under this assumption:                                  
bic1 <- function( x, sigma=1 ){

	# BIC = kln(n) - 2ln(L), with L the (max) likelihood, n = # data points, k = # model parms.
	
	# Likelihood: density of a bivariate Gaussian with mean = track starting
	# point, sd = sigma um in both directions (diagonal covariance matrix since
	# we assume measurement noise is independent in both directions).
	trackStart <- x[1,c("x","y")]
	allPoints <- x[,c("x","y")]
	Lpoints <- dmvnorm( allPoints, mean = colMeans(allPoints), sigma = sigma*diag(2), log = TRUE )
	
	# The likelihood of multiple independent events (track coordinates) is the product of the likelihood of
	# each individual event (coordinate), so L = L1 * L2 * ... * Ln for the n coordinates
	# of the track. But since we look at log likelihood, log( L ) = log( L1 * L2 * ... * Ln )
	# = log( L1 ) + log( L2 ) + ... + log( Ln ).
	logL <- sum( Lpoints )

	# BIC = kln(n) - 2ln(L); k = 2 (mean, sigma)
	return( 2*log(nrow(x)) - 2*logL )
}

# Alternative model: cell does move. We test this by saying that two Gaussians
# (for the beginning and the end of the track) fit better than just one; if that is the
# case, there was translation from the beginning to the end of the track beyond what
# can be explained with measurement error. 
# Compute BIC under this assumption, for a given cutoff point m (fit the first m coordinates
# with one Gaussian and everything after that with another).
sbic2 <- function( x, m, sigma=1 ){

	# BIC = kln(n) - 2ln(L), k = 5 now because we fit 2 Gaussians with mean and sd, but also m
	klogn <- 5*log(nrow(x))
	
	# log likelihood of the first m points fitted with one gaussian
	firstCoords <- x[1:m,c("x","y"), drop = FALSE]
	Lpoints1 <- dmvnorm( firstCoords, 
		mean = colMeans(firstCoords), sigma = sigma*diag(2), log = TRUE )
	
	# log likelihood of other coordinates fitted with a second gaussian
	lastCoords <- x[(m+1):nrow(x), c("x","y"), drop = FALSE]
	Lpoints2 <- dmvnorm( lastCoords, 
		mean = colMeans(lastCoords), sigma = sigma*diag(2), log = TRUE )

	logL <- sum( Lpoints1 ) + sum( Lpoints2 )
		
	return( klogn - 2*logL )
}


# BIC for the alternative hypothesis is the minimum BIC for all possible cutoffs.
bic2 <- function( x, sigma=1 ){
	min( sapply( 2:(nrow(x)-1), function(m) sbic2(x,m,sigma) ) )
}

# Our outcome is delta BIC, but this can become very large; so place a ceiling on the
# absolute values.
mink <- function( x, sigma=1, maxValue = 30 ){
	b1 <- bic1( x, sigma )
	b2 <- bic2( x, sigma )
	r <- b1 - b2
	if( abs(r) > maxValue ){
		r <- maxValue*sign(r)
	}
	r
}


# To filter out non-motile cells, set a threshold for this deltaBIC value
deltaBIC <- sapply( phagocyteData, mink, sigma = 1 )
nonMotile <- phagocyteData[ deltaBIC < 15 ]
motile <- phagocyteData[ deltaBIC >= 15 ]





# remove manually: border artefacts (cells that seem to move in an extremely straight line
# and are located right at the border).
names(motile) <- gsub( "100000", "", names(motile) )
removeIDs <- c("0002", "2537", "2011", "0013", "2015", "2653", "0033", "0043" )
filteredData <- motile[ !is.element( names(motile), removeIDs ) ]  

pdf("QC.pdf")
plot( phagocyteData, col = "white" )
plot( nonMotile, col = "blue" , add = TRUE )
plot( motile[removeIDs], col = "black", add = TRUE )
plot( filteredData, col = "red", add = TRUE )
dev.off()


                                  
pdf("featuremap.pdf")                                  
tmap <- trackFeatureMap( filteredData, c( outreachRatio, speed, maxDisplacement ), return.mapping = TRUE, method = "MDS" )
tmap <- cbind( tmap, ( tmap[,2] < -0.35 ) )
plot( tmap, col = as.numeric(tmap[,3])+1 ); abline( h = -0.35, col = "gray" )
finalSet <- filteredData[ tmap[,2] < -0.35  ]
plot( filteredData[ tmap[,2] >= -0.35  ], col = "black" )
plot( finalSet, col = "red", add = TRUE )
dev.off()





saveRDS( finalSet, outFile )

library( dplyr )
library( celltrackR )
library( ggplot2 )
library( ggbeeswarm )

argv <- commandArgs( trailingOnly = TRUE )


fMu <- argv[1]
fEGD <- argv[2]
outSpeed <- argv[3]
outMSD <- argv[4]

framerate <- 0.25

getTracks <- function( fName, framerate = 0.25 ){
	d <- read.csv( fName, skip = 3 )
	tt <- as.tracks( d, time.column = 7, id.column = 8, pos.columns = 1:2, scale.t = framerate )
	return(tt)
}

getSpeeds <- function( tracks.list, types ){

	df <- data.frame()
	for( i in 1:length(tracks.list) ){
		tracks <- tracks.list[[i]]
		type <- types[i]
		vi <- sapply( tracks, speed )
		dfi <- data.frame( v = vi, type = type )
		df <- rbind( df, dfi )
	}
	
	return(df)
}

getMSDs <- function( tracks.list, types ){

df <- data.frame()
	for( i in 1:length(tracks.list) ){
		tracks <- tracks.list[[i]]
		type <- types[i]
		msdi <- aggregate( tracks, squareDisplacement, FUN = "mean.se" )
		msdi$type <- type
		df <- rbind( df, msdi )
	}
	
	return(df)
}

tMu <- getTracks( fMu )
tEGD <- getTracks( fEGD )

dSpeed <- getSpeeds( list(tMu,tEGD), c("lmina","egd"))
	
m <- getMSDs( list( tMu, tEGD), c("lmina","egd" ) )
m$dt <- m$i * framerate


write.table( dSpeed, file = outSpeed, quote = FALSE, row.names =FALSE, sep = "," )
write.table( m, file = outMSD, quote = FALSE, row.names = FALSE, sep = "," )
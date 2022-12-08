library( celltrackR )
library( dplyr )
library( ggplot2 )
library( ggbeeswarm )

argv <- commandArgs( trailingOnly = TRUE )

outFile <- argv[3]

dN <- read.csv( argv[1] )
dLm <- read.csv( argv[2] )

getTracks <- function( df ){
	tt <- as.tracks( df, pos.columns = 1:2, time.column = 7, id.column = 8 )
	return(tt)
}

tN <- getTracks( dN )
tL <- getTracks( dLm )


vN <- sapply( tN, speed )
vL <- sapply( tL, speed )

lenN <- sapply( tN, nrow )
lenL <- sapply( tL, nrow )



dout <- rbind(
	data.frame( speed = vN, cell = "Neutrophils" ),
	data.frame( speed = vL, cell = "Lm.RT" )
)

write.table( dout, file = outFile, quote = FALSE, row.names = FALSE, sep = "," )

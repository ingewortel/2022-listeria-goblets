library( readxl )
library( dplyr )

argv <- commandArgs( trailingOnly = TRUE )

dirName <- argv[1]
outName <- argv[2]


dt <- (100/1000) #100msec


ff <- list.files( dirName )
tag <- letters[1:length(ff)]

flen <- c(0)

all.data <- bind_rows( lapply( 1:length(ff), function(i){
	fPath <- paste0( dirName, "/", ff[i] )
	di <- read_excel( fPath, skip = 1 )
	di$rows <- nrow(di)
	di$TrackID <- paste0( tag[i], as.character( di$TrackID) )
	di$Time <- di$Time * dt 
	di$file <- ff[i]
	return(di)
}) )


write.table( all.data, file = outName, quote = FALSE, row.names = FALSE, sep = "," )
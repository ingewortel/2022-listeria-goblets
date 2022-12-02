library( celltrackR )
suppressMessages( library( dplyr ) )

argv <- commandArgs( trailingOnly = TRUE )

trackFile <- argv[1]
type <- argv[2]
r <- as.numeric( argv[3] )
outFile <- argv[4]

tr <- readRDS( trackFile )

# Crowding analysis: too many tracks so filter the tracks that have at least one coordinate
# within r micron of the center of the imaging window:
center <- apply( boundingBox( tr ), 2, mean )
df <- as.data.frame( tr )
df <- df %>%
	mutate( 
		dx = x - center["x"],
		dy = y - center["y"],
		dist = sqrt( dx^2 + dy^2 )
	)
filter.IDs <- unique( df$id[ df$dist <= r ] )
filteredTr <- tr[ filter.IDs ]

if( type == "cells" ){
	df <- analyzeCellPairs( tr )
} else if (type == "steps" ){
	df <- analyzeStepPairs( tr )
}

saveRDS( df, file = outFile )
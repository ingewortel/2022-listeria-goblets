library( celltrackR )
suppressMessages( library( dplyr ) )

argv <- commandArgs( trailingOnly = TRUE )

tracks1 <- readRDS( argv[1] )
tracks2 <- readRDS( argv[2] )
groupNames <- unlist( strsplit( argv[3], " " ) )
bootstrapN <- as.numeric( argv[4] )
outFile <- argv[5]

speed1 <- data.frame( group = groupNames[1], speed = sapply( tracks1, speed ) ) 
speed2 <- data.frame( group = groupNames[2], speed = sapply( tracks2, speed ) ) 
speedData <- rbind( speed1, speed2 )

# For the bootstraps: every time, sample with replacement from the data (equal number of 
# rows to original data, so prop = 1 ) and compute means
bootstrapMeanDiff <- sapply( 1:bootstrapN, function(x){
	sample <- slice_sample( speedData, prop = 1, replace = TRUE )
	means <- sample %>% group_by( group ) %>% summarise( muSpeed = mean(speed) )
	# get the difference: group 2 - group 1
	meanDiff <- diff( means$muSpeed )
	return( meanDiff )
})


saveRDS( bootstrapMeanDiff, file = outFile )
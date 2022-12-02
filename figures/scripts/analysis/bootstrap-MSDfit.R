library( celltrackR )
source("../scripts/analysis/msd-fitting-functions.R")
suppressMessages( library( dplyr ) )
options(dplyr.summarise.inform = FALSE)

argv <- commandArgs( trailingOnly = TRUE )


trackFile <- argv[1]
outFile <- argv[2]
N <- as.numeric( argv[3] )


tr <- readRDS( trackFile )


# MSD per track:
message('...computing MSDs...')
MSDperTrack <- lapply( names(tr), function(x) getMSD(tr[x], mean, count.subtracks = TRUE ) %>% mutate( id = x ) )

# For bootstrapping: first generate N resampled datasets (sample tracks with replacement
# to get new track set of same size)
message('...getting samples...')
nTracks <- length(tr)
#samples <- lapply( 1:N, function(x){ tr[ sample.int( nTracks, replace = TRUE ) ] })
samples <- lapply( 1:N, function(x) sample.int( nTracks, replace = TRUE ) )

# On these samples, get MSDs
# msdList <- lapply( samples, function(x) getMSD(x, FUN = mean ) )
msdList <- lapply( samples, function(x) {
	# combine the MSDs per track into one
	merged <- dplyr::bind_rows( MSDperTrack[ x ] ) 
	
	# Per i/dt, need to compute *weighted* average
	corrected <- merged %>%
		group_by( i, dt ) %>%
		summarise( ncells = n(), mean = weighted.mean( mean, ntracks ) )
	
	return(corrected)
		
} )


# On these MSDs, compute fit
message('...fitting equation...')
parmList <- lapply( msdList, fitMSD, cutoff = 5 )

# bind rows into a dataframe
dfParms <- bind_rows( parmList )

saveRDS( dfParms, file = outFile )
message('...done!')
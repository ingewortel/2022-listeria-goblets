library( celltrackR )
suppressMessages( library( dplyr ) )
library( ggplot2 )
library( patchwork )
source("../scripts/plotting/prettylog.R")
source("../scripts/plotting/mytheme.R")

argv <- commandArgs( trailingOnly = TRUE )

datafile <- argv[1]
modelfile <- argv[2]
cells <- argv[3] # 'Listeria' or 'Neutrophils'
relSpeed <- as.numeric( argv[4] )
outplot <- argv[5]

# Handle some things depending on celltype:
plotColors <- c( data = "gray60" )
if( cells == "Listeria" ){

	plotColors["model"] <- "dodgerblue3"
	timeUnit <- "sec"
	pointSize <- 0.2
	
} else if ( cells == "Neutrophils" ){

 	plotColors["model"] <- "maroon3"
 	timeUnit <- "min"
 	pointSize <- 1

} else { stop( " 'cells' must be 'Listeria' or 'Neutrophils'! ") }

if( timeUnit == "sec" ){
	speedLab <- expression( "speed ("*mu*"m/sec)")
	dtLab <- expression(Delta*"t (sec)" )
} else {
	speedLab <- expression( "speed ("*mu*"m/min)")
	dtLab <- expression(Delta*"t (min)" )
}




maxOverlap <- Inf #0 #Inf

# Read the (preprocessed) neutrophil tracking data; this is already a celltrackR tracks object.
tData <- readRDS( datafile )

# Read model tracks. 2 pixels/micron so 0.5 micron/pixel entered in "scale.pos".
# scale.t depends on "relSpeed" (in seconds/MCS).
# This means that both datasets now have units of "microns" and "seconds".
tModel <- read.tracks.csv( modelfile, time.column = 1, id.column = 2, pos.columns = 4:5,
	scale.pos = 0.5, scale.t = 1/relSpeed ) 


# Data were simulated with a torus, so cells moving off the grid on the right re-enter on 
# the left. Analogous to cells moving out of the imaging window in real data, we split
# the tracks whenever cells cross the grid boundary:
splitAtTorus <- function( tracks ){
  
  # when track crosses the periodic boundary, its displacement is more than
  # 1x the grid dimension. Assuming that the grid is large enough, this would
  # otherwise never happen, so we threshold using something only slightly smaller than
  # the grid dimension. 
  dims <- apply( boundingBox( tracks ), 2, diff )
  maxDisp <- min( dims[c("x","y") ] ) * 0.8
  
  # find positions where tracks cross the periodic boundary;
  # these have displacements much larger than would be expected
  splitPositions <- lapply( tracks, function(x){
    unname( which( sapply( subtracks(x,1), displacement ) > maxDisp ) )
  })
  
  # apply splitTrack to split the tracks, then unlist to unnest the list again.
  tracks <- lapply( 1:length(tracks), function(x){
    splitTrack( tracks[[x]], splitPositions[[x]], min.length=20 )
  } )
  tracks <- as.tracks( unlist( tracks, recursive = FALSE ) ) 
  names(tracks) <- 1:length(tracks)
  return( tracks )
}
tModel <- splitAtTorus( tModel )

# Interpolate so the two have a similar delta_t. 
interpolateDataSteps <- function( tracks, tau ){
		tracks2 <- lapply( tracks, function(x){
		trange <- range( x[,"t"] )
		tr <- interpolateTrack( x, seq( trange[1], trange[2], by = tau ), "spline" )
		return(tr)
	})
	tracks2 <- as.tracks( tracks2 )
	names(tracks2) <- 1:length(tracks2)
	return(tracks2)
}
tModel <- interpolateDataSteps( tModel, timeStep( tData ) )



# speed plot
speedData <- data.frame( type = "data",
                         speed = sapply( tData, speed ) ) 
speedModel <- data.frame( type = "model",
                           speed = sapply( tModel, speed ) ) 

speeds <- rbind( speedData, speedModel )
if( timeUnit ==  "min" ) speeds$speed <- speeds$speed * 60 # x 60 to get per min instead of per sec
speeds$type <- factor( speeds$type, levels = c("data","model" ))
means <- speeds %>% group_by( type ) %>% summarise( speed = mean(speed ) ) 

pSpeed <- ggplot( speeds, aes( x = type, y = speed, color = type ) )  +
  ggbeeswarm::geom_quasirandom( shape = 16, show.legend = FALSE, size = pointSize ) +
  geom_segment( data = means, 
                size = 0.5,
                color = "black",
                aes( x = as.numeric(as.factor(type))-0.3, 
                     xend = as.numeric(as.factor(type)) + 0.3, 
                     y = speed, 
                     yend = speed ) )+
  scale_color_manual( values = plotColors ) +
  scale_y_continuous( limits = c(0,NA), expand = c(0,0) ) +
  labs( x = NULL, y = speedLab, color = NULL ) + 
  mytheme 
  
  
# MSD plot
getMSD <- function( tracks, tau = NULL, k = 1, max.overlap = maxTrackLength(tracks)-1 ){
  
  
  if( !is.null(tau) ){
    tracks <- interpolateDataSteps( tracks, tau )
  }
  if( k != 1 ){
    tracks <- subsample( tracks, k )
  }
  
  msd <- aggregate( tracks, squareDisplacement, max.overlap = max.overlap, FUN = "mean.se" )
  msd$dt <- msd$i * timeStep( tracks )
  if( timeUnit == "min" ) msd$dt <- msd$dt/60
  #msd <- msd[,c(3,2)]
  return(msd)
  
}

msdData <- getMSD( tData, max.overlap = maxOverlap ) %>% mutate( type = "data" )
msdModel <- getMSD( tModel, tau = timeStep( tData ), max.overlap = maxOverlap ) %>% mutate( type = "model" )
msdAll <- rbind( msdData, msdModel )
msdAll$type <- factor( msdAll$type, levels = c("data","model" ))

xrange <- c( 0, ceiling( max(log10(msdAll$dt*2)) ) )
yrange <- c( 1, ceiling( max(log10(msdAll$upper*2)) ) )


pMSD <- ggplot( msdAll, aes ( x = dt, y = mean, group = type, color = type, fill = type ) ) +
	geom_ribbon( aes( ymin = lower, ymax = upper ), alpha = 0.1, color = NA ) +
	geom_line() +
	scale_color_manual( values = plotColors ) +
	scale_fill_manual( values = plotColors ) +
	scale_prettylog( "x", labellogs = seq( xrange[1], xrange[2] ), limits = c(1, max(msdAll$dt[ msdAll$type == "data"] ) ) )  +
	scale_prettylog( "y", labellogs = seq( yrange[1], yrange[2]+1 ), limits = c(10,NA) ) +
	labs( x = dtLab,
		y  = "MSD", color = paste0(cells,":"), fill = paste0(cells,":") ) +
	mytheme + theme(
		legend.direction = "horizontal"
	)


# Acov plot
getAcov <- function( tracks, tau = NULL, k = 1, max.overlap = maxTrackLength(tracks)-1 ){
  
  
  if( !is.null(tau) ){
    tracks <- interpolateDataSteps( tracks, tau )
  }
  if( k != 1 ){
    tracks <- subsample( tracks, k )
  }
  
  acov <- aggregate( tracks, overallDot, max.overlap = max.overlap, FUN = "mean.se" )
  acov[,2:4] <- acov[,2:4]/acov$mean[1]
  acov$dt <- acov$i * timeStep( tracks )
  if( timeUnit == "min" ) acov$dt <- acov$dt/60
  return(acov)
  
}

acov.breaks <- seq(-0.5,1,by=0.25)
acov.labels <- acov.breaks
acov.labels[ seq_along(acov.labels) %% 2 == 0 ] <- ""

acovData <- getAcov( tData, max.overlap = maxOverlap ) %>% mutate( type = "data" )
acovModel <- getAcov( tModel, tau = timeStep( tData ), max.overlap = maxOverlap ) %>% mutate( type = "model" )
acovAll <- rbind( acovData, acovModel )
acovAll$type <- factor( acovAll$type, levels = c("data","model" ))
pAcov <- ggplot( acovAll, aes ( x = dt, y = mean, ymin = lower, ymax = upper, fill = type, group = type, color = type ) ) +
	geom_hline( yintercept = 0, size = 0.3 ) +
	geom_ribbon( aes(  ), alpha = 0.1, color = NA ) +
	geom_line() +
	scale_color_manual( values = plotColors ) +
	scale_fill_manual( values = plotColors ) +
	labs( x = dtLab,
		y  = "norm. autocov", color = paste0(cells,":"), fill = paste0(cells,":") ) +
	scale_x_continuous( expand=c(0,0), limits = c(0, max(acovAll$dt[ acovAll$type == "data"] ) ))+
	scale_y_continuous( limits=c(NA,NA), expand = c(0,0), breaks =acov.breaks, labels = acov.labels ) +
	mytheme + theme(
		legend.direction = "horizontal"
	)



#p <- pSpeed | ( pMSD / pAcov )
#ggsave( outplot, width = 10, height = 6, useDingbats = FALSE )
p <- pSpeed + pMSD + pAcov +
	plot_layout( widths = c(2,3,3 ) )
ggsave( outplot, width = 16, height = 5.5, units = "cm", useDingbats = FALSE )

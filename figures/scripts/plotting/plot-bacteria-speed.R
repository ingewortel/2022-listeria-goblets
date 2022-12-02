library( celltrackR )
suppressMessages( library( dplyr ) )
library( ggplot2 )
library( ggbeeswarm )
library( patchwork )
library( ggtext )
source("../scripts/plotting/prettylog.R")
source("../scripts/plotting/mytheme.R")
source("../scripts/analysis/deltaBIC.R")

plotColors <- c( "Lm-37-NM" = "darkorange", "Lm-37-M" = "dodgerblue3", "Lm-RT-M" = "dodgerblue3", "Lm-RT-NM" = "darkorange" )
BICthresh <- 0

argv <- commandArgs( trailingOnly = TRUE )

file37 <- argv[1]
fileRT <- argv[2]
outPlot <- argv[3]


# =================== Data

tracks37 <- readRDS( file37 )
tracksRT <- readRDS( fileRT )




# =================== Speed plots

# ------ Compute cell-based speeds and add deltaBIC to detect motility

speed37 <- data.frame( 
		temp = "Lm-37",
		id = names( tracks37 ),
		speed = sapply( tracks37, speed ),
		dBIC = sapply( tracks37, deltaBIC, sigma = 1 )
	) %>%
	mutate( motile = ifelse( dBIC >= BICthresh , "M","NM" ),
		type = paste0( temp, "-", motile ) )
speedRT <- data.frame( 
		temp = "Lm-RT", 
		id = names( tracksRT ),
		speed = sapply( tracksRT, speed ),
		dBIC = sapply( tracksRT, deltaBIC, sigma = 1 ) 
	) %>%
	mutate( motile = ifelse( dBIC >= BICthresh , "M","NM" ), # speed >= 1.25
		type = paste0( temp, "-", motile ) )
speedData <- rbind( speed37, speedRT )
speedMeans <- speedData %>% group_by( temp ) %>% summarise( mu = mean(speed) )

# ------ Fraction of non-motile cells for plot annotation

frac37 <- sum( speed37$dBIC < BICthresh  )/nrow( speed37 ) # fraction non-motile
fracRT <- sum( speedRT$dBIC < BICthresh  )/nrow( speedRT ) # fraction non-motile


# ------ Plot speed distributions

# plot mean speed per track and show the population mean of the (untransformed) speeds,
# but show on a log scale to see the difference. 
pSpeedNormal <- ggplot( speedData, aes( x = temp, y = speed, color = type ) ) + 
	geom_quasirandom( size = 0.1, shape = 16, show.legend = FALSE ) +
	geom_segment( data = speedMeans, 
                size = 0.5,
                color = "black",
                aes( x = as.numeric(as.factor(temp))-0.3, 
                     xend = as.numeric(as.factor(temp)) + 0.3, 
                     y = mu, 
                     yend = mu ) )+
    scale_color_manual( values = plotColors ) +
	labs( x = NULL, y = expression( "mean track speed ("*mu*"m/sec)")) +
	mytheme

# add log version
yrange <- c(-2, ceiling(max(log10(speedData$speed*2))) ) # in log
pSpeedLog <- pSpeedNormal + 
	scale_prettylog( "y", labellogs = seq( yrange[1], yrange[2] ), limits = 10^yrange ) +
	annotate( "text", x = "Lm-37", y = 0.02, label = paste0(100*frac37,"% static"), size = (5/14)*6, color = plotColors["Lm-37-NM"] ) +
	annotate( "text", x = "Lm-RT", y = 0.02, label = paste0(round(100*fracRT),"% static"), size = (5/14)*6, color = plotColors["Lm-RT-NM"] ) +
	annotate( "text", x = "Lm-RT", y = 60, label = paste0(100-round(100*fracRT),"% motile"), size = (5/14)*6, color = plotColors["Lm-RT-M"] )






# =================== Track plots



# ------ Tracks in a dataframe; add motility info based on deltaBIC

df37 <- as.data.frame( tracks37 ) 
motile.37 <- speed37$id[ speed37$dBIC >= BICthresh  ]
df37 <- df37 %>%
	mutate( temp = "Lm-37", motile = ifelse(  id %in% motile.37, "M","NM" ),
		type = paste0( temp, "-", motile ) )

dfRT <- as.data.frame( tracksRT )
motile.RT <- speedRT$id[ speedRT$dBIC >= BICthresh  ]
dfRT <- dfRT %>%
		mutate( temp = "Lm-RT", motile = ifelse(  id %in% motile.RT, "M","NM" ),
		type = paste0( temp, "-", motile ) )

# ------ Track starting points for annotation in the plot

df37start <- df37 %>% group_by( id ) %>% filter( t == min(t) )
dfRTstart <- dfRT %>% group_by( id ) %>% filter( t == min(t) )

# ------ Compute coordinates for the zoomed version

corner37 <- boundingBox( tracks37 )["max",c("x","y")]
cornerRT <- boundingBox( tracksRT )["max",c("x","y")]
window.size <- 50
offset <- 10
zoom.window.37 <- c( corner37["x"] - window.size - offset, corner37["x"] - offset, corner37["y"] - window.size - offset, corner37["y"] - offset )
zoom.window.RT <- c( cornerRT["x"] - window.size - offset, cornerRT["x"] - offset, cornerRT["y"] - window.size - offset, cornerRT["y"] - offset )

# ------ Track plots

p37 <- ggplot( df37, aes( x = x, y = y, group = id, color = type ) ) +
	geom_path( show.legend = FALSE, size = 0.2 ) +
	geom_point( data = df37start, shape = 16, size = 0.3, show.legend = FALSE ) +
	scale_color_manual( values = plotColors ) +
	labs( title = "Lm-37", color = NULL ) + #expression( Lm^"Mu"*" 37°C")
	annotate( "rect", xmin= zoom.window.37[1], xmax=zoom.window.37[2], ymin=zoom.window.37[3], ymax=zoom.window.37[4], fill = NA , color="black", size=0.2 ) +
	coord_fixed() +
	mytheme + theme(
		axis.ticks = element_blank(),
		axis.text.x = element_blank(),
		axis.text.y = element_blank(),
		axis.title = element_blank(),
		plot.title = element_text(hjust = 0.5)
	)

pRT <- ggplot( dfRT, aes( x = x, y = y, group = id, color = type ) ) +
	geom_path( aes( alpha = type ), show.legend = FALSE, size = 0.2 ) +
	geom_point( data = dfRTstart, shape = 16,   size = 0.2, show.legend = FALSE ) +
	scale_color_manual( values = plotColors ) +
	scale_alpha_manual( values = c( "Lm-RT-M" = 0.2, "Lm-RT-NM" = 1 ) ) +
	annotate( "rect", xmin= zoom.window.RT[1], xmax=zoom.window.RT[2], ymin=zoom.window.RT[3], ymax=zoom.window.RT[4], fill = NA , color="black", size=0.2 ) +
	coord_fixed() +
	labs( title = "Lm-RT")+ #expression( Lm^"Mu"*" RT")) +
	mytheme + theme(
		axis.ticks = element_blank(),
		axis.text.x = element_blank(),
		axis.text.y = element_blank(),
		axis.title = element_blank(),
		plot.title = element_text(hjust = 0.5)
	)

# ------ Zoomed insets

p37zoom <- ggplot( df37, aes( x = x, y = y, group = id, color = type ) ) +
	geom_path( show.legend = FALSE, size = 0.6 ) +
	geom_point( data = df37start, shape = 16, size = 0.9, show.legend = FALSE ) +
	scale_color_manual( values = plotColors ) +
	scale_x_continuous( expand = c(0,0) ) +
	scale_y_continuous( expand = c(0,0) ) +
	labs( color = NULL ) +
	coord_fixed( xlim = zoom.window.37[1:2],ylim=zoom.window.37[3:4] ) +
	mytheme + theme(
		axis.ticks = element_blank(),
		axis.text.x = element_blank(),
		axis.text.y = element_blank(),
		axis.title = element_blank(),
		plot.margin = unit(c(0.1,0.1,0.1,-1.5),"cm")
	)
	
pRTzoom <- ggplot( dfRT, aes( x = x, y = y, group = id, color = type ) ) +
	geom_path( aes( alpha = type ), show.legend = FALSE, size = 0.6 ) +
	geom_point( data = dfRTstart, shape = 16, size = 0.9, show.legend = FALSE ) +
	scale_color_manual( values = plotColors ) +
	scale_alpha_manual( values = c( "Lm-RT-M" = 0.2, "Lm-RT-NM" = 0.5 ) ) +
	scale_x_continuous( expand = c(0,0) ) +
	scale_y_continuous( expand = c(0,0) ) +
	labs( color = NULL ) +
	annotate( "rect", xmin= zoom.window.RT[1], xmax=zoom.window.RT[2], ymin=zoom.window.RT[3], ymax=zoom.window.RT[4], fill = NA , color="black", size=0.2 ) +
	coord_fixed( xlim = zoom.window.RT[1:2],ylim=zoom.window.RT[3:4] ) +
	mytheme + theme(
		axis.ticks = element_blank(),
		axis.text.x = element_blank(),
		axis.text.y = element_blank(),
		axis.title = element_blank(),
		plot.margin = unit(c(0.1,0.1,0.1,-1.5),"cm")
	)
	
	



# =================== Final patchwork


design <- "
AACCCEE
AACCCEE
BBDDDFF
BBDDDFF
"

# design <- c(
# 	area( t = 1, l = 1, b = 4, r = 3 ),
# 	area( t = 1, l = 4, b = 4, r = 6 ),
# 	area( t = 5, l = 1, b = 8, r = 4 ),
# 	area( t = 5, l = 5, b = 8, r = 8 )
# )

p <- pSpeedNormal + pSpeedLog + p37 + pRT + p37zoom + pRTzoom + 
	plot_layout( design = design, heights = c(1,1) )
ggsave( outPlot, width = 14.5, height = 9, units = "cm", useDingbats = FALSE )




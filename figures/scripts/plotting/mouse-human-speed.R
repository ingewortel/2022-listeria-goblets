library( celltrackR )
suppressMessages( library( dplyr ) )
library( ggplot2 )
library( ggbeeswarm )
library( patchwork )
library( geomtextpath )
library( scales )
source("../scripts/plotting/prettylog.R")
source("../scripts/plotting/mytheme.R")

plotColors <- c( "egd" = "red", "lmina" = "gray40", "EGD" = "red", "Lm^'Mu'" = "gray40" )

argv <- commandArgs( trailingOnly = TRUE )

dataFile <- argv[1]
msdFile <- argv[2]
outPlot <- argv[3]

# DATA
speedData <- read.csv( dataFile, header = TRUE ) %>%
	mutate( listeria = type, speed = v )
lookUp <- c( "egd"="EGD", "lmina" = "Lm^'Mu'"  )
speedData$listeria2 <- lookUp[ speedData$listeria ]


msdData <- read.csv( msdFile, header = TRUE )  %>%
	mutate( speed = mean ) %>%
	mutate( listeria = type ) 
msdData$listeria2 <- lookUp[ msdData$listeria ]



speedMeans <- speedData %>% group_by( listeria) %>% summarise( mu = mean(speed) )
yrange <- c(-2, ceiling(max(log10(speedData$speed*2))) ) # in log

# plot mean speed per track and show the population mean of the (untransformed) speeds,
# but show on a log scale to see the difference. 
pSpeedNormal <- ggplot( speedData, aes( x = listeria2, y = speed, color = listeria ) ) + 
	geom_quasirandom( size = 0.1, shape = 16, show.legend = FALSE ) +
	#geom_hline( alpha = 0.5, data = speedMeans, aes( yintercept = mu, color = temp ), lty = 1, size = 0.25, show.legend = FALSE ) +
	geom_segment( data = speedMeans, 
                size = 0.5,
                color = "black",
                aes( x = as.numeric(as.factor(listeria))-0.3, 
                     xend = as.numeric(as.factor(listeria)) + 0.3, 
                     y = mu, 
                     yend = mu ) )+
    scale_color_manual( values = plotColors ) +
    scale_x_discrete( labels = label_parse() ) +
    scale_y_continuous( limits = c(0,NA ) ) +
	labs( x = NULL, y = expression( "track speed ("*mu*"m/s)")) +
	mytheme + theme(
		plot.margin = unit(c(0.1,0,0.1,0),"cm"),
		axis.text.x = element_text(size=5.5)
	)

pSpeedLog <- pSpeedNormal + scale_prettylog( "y", labellogs = seq( yrange[1], yrange[2] ), limits = 10^yrange )


msdData$hjust <- ifelse( msdData$listeria == "egd", 0.7, 0.85 )

# Compare MSD
pMSD <- ggplot( msdData, aes ( x = dt, y = mean, group = listeria, color = listeria, fill = listeria ) ) +
	geom_ribbon( aes( ymin = lower, ymax = upper ), alpha = 0.2, color = NA, show.legend = FALSE ) +
	#geom_line() +
	#geom_textline( data = msdData[ msdData$listeria == "egd",], 
	#	aes( label = listeria2 , vjust = -0.4, hjust = 0.6), parse = TRUE, size = 2, linewidth = .5, 
	#	show.legend = FALSE) + 
	geom_textline( 
		aes( label = listeria2 , hjust = hjust), vjust = -0.3, parse = TRUE, size = 2, linewidth = .5, 
		show.legend = FALSE) + 
	scale_color_manual( values = plotColors ) +
	scale_fill_manual( values = plotColors ) +
	scale_x_continuous( limits = c(0,max( msdData$dt )), expand = c(0,0) )+
	scale_y_continuous( limits = c(-50,NA), expand = c(0,0) ) +
	labs( x = expression( Delta*"t (sec)"),
		y  = expression( MSD*" ("*mu*"m"^2*")"),
		color = NULL, fill = NULL ) +
	mytheme 



design <- "
AABB
"

p <- pSpeedNormal + pMSD + 
	plot_layout( design = design ) 
ggsave( outPlot, width = 8, height = 5, units = "cm", useDingbats = FALSE )
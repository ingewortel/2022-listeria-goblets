library( ggplot2 )
suppressMessages( library( dplyr ) ) 
library(tidyr)
library( patchwork )

source("../scripts/plotting/mytheme.R")



argv <- commandArgs( trailingOnly = TRUE )

settingsFile <- argv[1]
eventFile <- argv[2]
outPlot <- argv[3]

parms <- read.table( settingsFile, sep = "\t", header = TRUE )
dplot <- readRDS( eventFile )

percentages <- TRUE
plotColors <- c( "sLm-37" = "gray", "sLm-RT" = "dodgerblue3" )

# set the temperature variable and select the columns of interest
dplot <- dplot %>% 
	mutate( temp = ifelse( x == 0, "sLm-37", "sLm-RT" )) %>%
	select( temp, sim, nStart, tp, n, type ) %>%
	filter( type != "free" ) # this column is wrong now that we have attachment.
	
# Get final counts for each population in separate columns.
dcum <- dplot %>%
	mutate( temp = as.factor(temp)) %>%
	group_by( temp, sim, type, nStart ) %>%
	filter( n == last(n) ) %>%	
	mutate( tp = max( dplot$tp ) ) %>%
	pivot_wider( values_from = n, names_from = type ) %>%
	mutate( attached = NA, pI = 100*invaded/nStart, pP = 100*phagocytosed/nStart ) # attached unknown exactly because this includes also bacteria that were later infected/phagocytosed.


dMean <- dcum %>%
	group_by( nStart, temp, tp ) %>% 
	summarise(
		sd_i = sd(invaded),
		invaded = mean(invaded ), 
		sd_p = sd( phagocytosed ),
		phagocytosed = mean( phagocytosed ),
		pI = 100*invaded/nStart, 
		pP = 100*phagocytosed/nStart,
		sd_pI = 100*sd_i/nStart,
		sd_pP = 100*sd_p/nStart
	)

pI <- ggplot( dcum, aes( x = temp, y = pI, color = temp ) ) +
	ggbeeswarm::geom_quasirandom( show.legend = FALSE, size = .5 )+
	geom_segment( data = dMean, aes( x = as.numeric(temp)-0.3, xend = as.numeric(temp)+0.3,
		y = pI, yend = pI ), color="black" ) +
	scale_y_continuous( limits=c( 0, 100 ), expand = c(0,0 ) ) +
	scale_color_manual( values =  plotColors) +
	scale_fill_manual( values = plotColors ) +
	labs( x = "bacteria", y = "% sLm invaded", color = NULL, title = "Invaded (60min)" ) +
	mytheme + theme(
		axis.title.y = element_blank()
	)

pP <- ggplot( dcum, aes( x = temp, y = pP, color = temp ) ) +
	ggbeeswarm::geom_quasirandom( show.legend = FALSE, size = .5 )+
	geom_segment( data = dMean, aes( x = as.numeric(temp)-0.3, xend = as.numeric(temp)+0.3,
		y = pP, yend = pP ), color="black" ) +
	scale_y_continuous( limits=c( 0, 100 ), expand = c(0,0 ) ) +
	scale_color_manual( values =  plotColors) +
	scale_fill_manual( values = plotColors ) +
	labs( x = "bacteria", y = "% sLm phagocytosed", color = NULL, title = "Phagocytosed (60min)" ) +
	mytheme + theme(
		axis.title.y = element_blank()
	)
	
pY <- ggplot( data.frame( l = "% sLm", x = 1, y = 1 ) ) +
	geom_text( aes(x,y,label=l), angle = 90, size = (5/14)*7 ) +
	theme_void() +
	coord_cartesian( clip = "off" )

	
p <- pY + (pI | pP ) + plot_layout( ncol = 2, widths = c(1,25) )

ggsave( outPlot, width = 7.2, height = 4.5, units = "cm", useDingbats = FALSE )


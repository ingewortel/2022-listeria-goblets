library( ggplot2 )
suppressMessages( library( dplyr ) ) 
library(tidyr)
library( patchwork )

source("../scripts/plotting/mytheme.R")



argv <- commandArgs( trailingOnly = TRUE )

eventFile <- argv[1]
eventsControl <- argv[2]
outPlot <- argv[3]

percentages <- TRUE
plotColors <- c( "non-motile" = "gray", "motile" = "maroon3" )

d1 <- readRDS( eventFile ) %>% 
	filter( x == 40) %>%
	mutate( l = 400, m = 20 )


d2 <- readRDS( eventsControl )

# combine and filter the endpoint data, rename some columns, select cols of interest
dplot <- rbind( d1, d2 ) %>%
	filter( t == max(t), v == 150 ) %>%
	mutate( phagocytes = ifelse( l == 0, "non-motile", "motile" ) ) %>%
	mutate( nStart = b, tp = t, invaded = infection, phagocytosed = phagocytosis ) %>%
	select( phagocytes, sim, nStart, tp, invaded, phagocytosed ) %>%
	mutate( pI = 100*invaded/nStart, pP = 100*phagocytosed/nStart ) %>%
	mutate(phagocytes = factor( phagocytes, levels = c( "non-motile", "motile" ) )) 
	
dMean <- dplot %>%
	group_by( nStart, phagocytes, tp ) %>% 
	summarise(
		sd_i = sd(invaded),
		invaded = mean(invaded ), 
		sd_p = sd( phagocytosed ),
		phagocytosed = mean( phagocytosed ) ) %>%
	mutate(
		pI = 100*invaded/nStart, 
		pP = 100*phagocytosed/nStart,
		sd_pI = 100*sd_i/nStart,
		sd_pP = 100*sd_p/nStart
	)

pI <- ggplot( dplot, aes( x = phagocytes, y = pI, color = phagocytes ) ) +
	ggbeeswarm::geom_quasirandom( show.legend = FALSE, size = .5 )+
	geom_segment( data = dMean, aes( x = as.numeric(phagocytes)-0.3, xend = as.numeric(phagocytes)+0.3,
		y = pI, yend = pI ), color="black" ) +
	scale_y_continuous( limits=c( 0, 100 ), expand = c(0,0 ) ) +
	scale_color_manual( values =  plotColors) +
	scale_fill_manual( values = plotColors ) +
	labs( x = "phagocytes", y = "% sLm invaded", color = NULL, title = "Invaded (60min)" ) +
	mytheme + theme(
		axis.title.y = element_blank()
	)

pP <- ggplot( dplot, aes( x = phagocytes, y = pP, color = phagocytes ) ) +
	ggbeeswarm::geom_quasirandom( show.legend = FALSE, size = .5 )+
	geom_segment( data = dMean, aes( x = as.numeric(phagocytes)-0.3, xend = as.numeric(phagocytes)+0.3,
		y = pP, yend = pP ), color="black" ) +
	scale_y_continuous( limits=c( 0, 100 ), expand = c(0,0 ) ) +
	scale_color_manual( values =  plotColors) +
	scale_fill_manual( values = plotColors ) +
	labs( x = "phagocytes", y = "% sLm phagocytosed", color = NULL, title = "Phagocytosed (60min)" ) +
	mytheme + theme(
		axis.title.y = element_blank()
	)
	
pY <- ggplot( data.frame( l = "% sLm", x = 1, y = 1 ) ) +
	geom_text( aes(x,y,label=l), angle = 90, size = (5/14)*7 ) +
	theme_void() +
	coord_cartesian( clip = "off" )

	
p <- pY + (pI | pP ) + plot_layout( ncol = 2, widths = c(1,25) )


ggsave( outPlot, width = 7.2, height = 4.5, units = "cm", useDingbats = FALSE )


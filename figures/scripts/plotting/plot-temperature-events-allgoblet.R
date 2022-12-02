library( ggplot2 )
suppressMessages( library( dplyr ) ) 
library(tidyr)

source("../scripts/plotting/mytheme.R")



argv <- commandArgs( trailingOnly = TRUE )

settingsFile <- argv[1]
eventFile <- argv[2]
nBac <- as.numeric(argv[3])
showWhich <- argv[4]
outPlot <- argv[5]

parms <- read.table( settingsFile, sep = "\t", header = TRUE )
dplot <- readRDS( eventFile )

percentages <- TRUE
plotColors <- c( "sLm-37" = "gray", "sLm-RT" = "dodgerblue3" )

# set the temperature variable and select the columns of interest
dplot <- dplot %>% 
	mutate( temp = ifelse( x == 0, "sLm-37", "sLm-RT" )) %>%
	select( temp, sim, nStart, tp, n, type ) %>%
	filter( type != "free" ) # this column is wrong now that we have attachment.
	
# Get cumulative counts for each population in separate columns.
# If a column is not in there, add it with zeros:
cols <- c(attached = 0, invaded = 0, phagocytosed = 0)

# Pivot-wider introduces NA values (e.g. when attachment at t = 3 and invasion at t = 5,
# invasion will be NA at t = 3 and attachment at t = 5). Fix this by imputation: set
# the n for these NA values equal to the last known n. 
dcum <- dplot %>%
	group_by( temp, sim, tp, type, nStart ) %>%
	summarise( n = last(n) ) %>% 							# if multiple events at this time, take the endpoint
	pivot_wider( values_from = n, names_from = type ) %>%
	tibble::add_column(!!!cols[!names(cols) %in% names(.)]) %>%
	group_by( nStart, temp ) %>%
	complete( sim, tp ) %>%
	group_by( nStart, temp, sim ) %>%	
	mutate( attached = zoo::na.locf(attached),
		invaded = zoo::na.locf(invaded),
		phagocytosed = zoo::na.locf(phagocytosed),
		attached = attached - invaded,
		pI = 100*invaded / nStart,
		pA = 100*attached / nStart,
		pP = 100*phagocytosed/nStart ) # once invaded no longer in attached po


dMean <- dcum %>%
	group_by( nStart, temp, tp ) %>% 
	summarise(
		lo_i = quantile(invaded,0.25),
		hi_i = quantile(invaded,0.75),
		invaded = mean(invaded ), 
		lo_a = quantile( attached, 0.25),
		hi_a = quantile( attached, 0.75 ),
		attached = mean(attached ), 
		lo_p = quantile( phagocytosed, 0.25 ),
		hi_p = quantile( phagocytosed, 0.75 ),
		phagocytosed = mean( phagocytosed ),
		pI = 100*invaded/nStart, 
		pA = 100*attached/nStart,
		pP = 100*phagocytosed/nStart,
		lo_pI = 100*lo_i/nStart,
		hi_pI = 100*hi_i/nStart,
		lo_pA = 100*lo_a/nStart,
		hi_pA = 100*hi_a/nStart,
		lo_pP = 100*lo_p/nStart,
		hi_pP = 100*hi_p/nStart
	)

if( showWhich == "attached" ){
	if( percentages ){
		dcum$n <- dcum$pA
		dMean$lo <- dMean$lo_pA
		dMean$hi <- dMean$hi_pA
		dMean$n <- dMean$pA
	} else {	
		dcum$n <- dcum$attached
		dMean$n <- dMean$attached
		dMean$hi <- dMean$hi_a
		dMean$lo <- dMean$lo_a
	}
} else if ( showWhich == "invaded" ) {
	if( percentages ){
		dcum$n <- dcum$pI
		dMean$lo <- dMean$lo_pI
		dMean$hi <- dMean$hi_pI
		dMean$n <- dMean$pI
	} else {	
		dcum$n <- dcum$invaded
		dMean$n <- dMean$invaded
		dMean$hi <- dMean$hi_i
		dMean$lo <- dMean$lo_i
	}
} else if ( showWhich == "phagocytosed" ) {
	if( percentages ){
		dcum$n <- dcum$pP
		dMean$lo <- dMean$lo_pP
		dMean$hi <- dMean$hi_pP
		dMean$n <- dMean$pP
	} else {	
		dcum$n <- dcum$phagocytosed
		dMean$n <- dMean$phagocytosed
		dMean$hi <- dMean$hi_p
		dMean$lo <- dMean$lo_p
	}
}

if( percentages ){
	ylab <- paste0( "% sLm ", showWhich )
	ymax <- 100
} else {
	ylab <- paste0( "# sLm ", showWhich )
	ymax <- max(dplot$nStart)
}

p <- ggplot( dcum, aes( x = tp/60, y = n, group = interaction(temp,sim), color = temp ) ) +
	geom_path( size = 0.1, alpha = 0.4 ) +
	#geom_ribbon( data = dMean, aes( ymin = lo, ymax = hi, group = temp, fill = temp ), color = NA, alpha = 0.2, show.legend = FALSE ) +
	geom_line( data = dMean, aes( group = temp ) ) +
	scale_x_continuous( limits=c( 0, 2 ), expand = c(0,0 ), breaks=seq(0,2) ) +
	scale_y_continuous( limits=c( 0, ymax ), expand = c(0,0 ) ) +
	scale_color_manual( values =  plotColors) +
	scale_fill_manual( values = plotColors ) +
	labs( x = "time (min)", y = ylab, color = NULL ) +
	mytheme + theme(
		legend.position = c(1,0),
		legend.justification = c(1,0)
	)


ggsave( outPlot, width = 4, height = 3.5, units = "cm", useDingbats = FALSE )


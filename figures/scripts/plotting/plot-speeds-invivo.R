library( ggplot2 )
library( dplyr, warn.conflicts = FALSE )
library( tidyr )
library( boot )
library( simpleboot )
library( see ) 			# half violin plots
library( ggbeeswarm )	# beeswarm plots
source("../scripts/plotting/mytheme.R")
library( patchwork )

set.seed(1234)

argv <- commandArgs( trailingOnly = TRUE )

speedFile <- argv[1]
outFile <- argv[2]

d <- read.table( speedFile, header = TRUE, sep = "\t" ) %>%
	pivot_longer( cols = 1:2, names_to = "cell", values_to = "speed" ) %>%
	mutate( cell = factor( cell, levels = c("Neutrophils","Lm.RT") ) ) %>%
	na.omit()

# Subset samples
LmRT <- d$speed[ d$cell == "Lm.RT" ]
Neut <- d$speed[ d$cell == "Neutrophils" ]

# bootstrap fold-change Lm.RT/Neutrophils; 
# large sample size so percentile method is valid.
logOfMean <- function(x){
	return( log( mean( x) ))
}
lm.boot <- two.boot( LmRT, Neut, logOfMean, R = 100000 )
ci <- exp( boot.ci( lm.boot, type="perc" )$percent[4:5])
print(ci)
estimate <- exp( logOfMean( LmRT ) - logOfMean( Neut ) )#exp( mean( log(LmRT+.5) ) - mean( log(Lm37+.5) ) ) 
print(estimate)

dboot <- data.frame( x = 2.8, y = exp(lm.boot$t) * mean(Neut) )
plotColors <- c( "Neutrophils" = "gray", "Lm.RT" = "gray40" )


# plot
p <- ggplot( d, aes( x = as.numeric(cell), y = speed ) ) +
	annotate( "segment", x = 1, xend = 2.8, y = mean( Neut), yend = mean( Neut), 
		size = .3, color = plotColors["Neutrophils"], lty = 2 )+
	annotate( "segment", x = 2, xend = 2.8, y = mean( LmRT), yend = mean( LmRT), 
		size = .3, color = plotColors["Lm.RT"], lty = 2 )+
	geom_quasirandom( size = .2, aes( color = cell ), show.legend = FALSE ) +
	geom_violinhalf( data = dboot, aes( x = x, y = y ), color = NA, fill = "gray40", alpha = .5, flip = TRUE ) +
	annotate( "segment", x = 2.8, xend = 2.8, y = ci[1] * mean(Neut ), yend = ci[2] * mean(Neut ) ) +
	annotate( "point", x = 2.8, y = estimate * mean(Neut ) ) +
	labs( x = " ", y = expression( "mean track speed ("*mu*"m/s)"), title = "Speed in explant (f = 100ms)" ) +
	coord_cartesian( ylim = c(-2,100), xlim = c(0.5,2.9), expand = FALSE ) +
	scale_y_continuous( 
		sec.axis = sec_axis(~( ./ mean(Neut)), name = "Fold-change",
			breaks = c(1,50,100) ) ) +
	scale_x_continuous( breaks = c(1,2), labels = c("Neutrophils", "Lm-RT") ) +
	scale_color_manual( values = plotColors ) +
	mytheme +
	theme( axis.line = element_blank() )
	

	
ggsave( outFile, plot = p, width = 5, height = 4.1, units = "cm" )
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

inFile <- argv[1]
outFile <- argv[2]

d <- read.table( inFile, header = TRUE ) %>%
	pivot_longer( cols = 1:2, names_to = "bacteria", values_to = "count" ) %>%
	mutate( bacteria = factor( bacteria, levels = c("flaA.mut","X10403") ) ) %>%
	na.omit()

# Subset samples
wt <- d$count[ d$bacteria == "X10403" ]
flaA.mut <- d$count[ d$bacteria == "flaA.mut" ]

# bootstrap fold-change Lm.RT/Neutrophils; 
# large sample size so percentile method is valid.
logOfMean <- function(x){
	return( log( mean( x) ))
}
lm.boot <- two.boot( wt, flaA.mut, logOfMean, R = 100000 )
ci <- exp( boot.ci( lm.boot, type="perc" )$percent[4:5])
print(ci)
estimate <- exp( logOfMean( wt ) - logOfMean( flaA.mut ) )#exp( mean( log(LmRT+.5) ) - mean( log(Lm37+.5) ) ) 
print(estimate)

dboot <- data.frame( x = 2.8, y = exp(lm.boot$t) * mean(flaA.mut) )
plotColors <- c( "flaA.mut" = "gray", "X10403" = "black" )


# plot
p <- ggplot( d, aes( x = as.numeric(bacteria), y = count ) ) +
	annotate( "segment", x = 1, xend = 2.8, y = mean( flaA.mut ), yend = mean( flaA.mut ), 
		size = .3, color = plotColors["flaA.mut"], lty = 2 )+
	annotate( "segment", x = 2, xend = 2.8, y = mean( wt), yend = mean( wt ), 
		size = .3, color = plotColors["X10403"], lty = 2 )+
	geom_quasirandom( size = .2, aes( color = bacteria ), show.legend = FALSE ) +
	geom_violinhalf( data = dboot, aes( x = x, y = y ), color = NA, fill = "forestgreen", alpha = .5, flip = TRUE ) +
	annotate( "segment", x = 2.8, xend = 2.8, y = ci[1] * mean( flaA.mut ), yend = ci[2] * mean(flaA.mut ) ) +
	annotate( "point", x = 2.8, y = estimate * mean( flaA.mut ) ) +
	labs( x = " ", y = "green voxels" ) +
	coord_cartesian( ylim = c(-2,NA), xlim = c(0.5,2.9), expand = FALSE ) +
	scale_y_continuous( 
		sec.axis = sec_axis(~( ./ mean(flaA.mut)), name = "Fold-change (w.r.t. flaA mut)",
			breaks = c(1,10,20,30,40,50) ) ) +
	scale_x_continuous( breaks = c(1,2), labels = c("flaA mutant","10403") ) +
	scale_color_manual( values = plotColors ) +
	mytheme +
	theme( axis.line = element_blank() )
	

	
ggsave( outFile, plot = p, width = 5, height = 4.1, units = "cm" )
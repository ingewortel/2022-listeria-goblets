library( ggplot2 )
library( dplyr )
library( tidyr )
library( boot )
library( simpleboot )
library( see ) 			# half violin plots
library( ggbeeswarm )	# beeswarm plots
source("../scripts/plotting/mytheme.R")
library( patchwork )

argv <- commandArgs( trailingOnly = TRUE )

countFile <- argv[1]
cfuFile <- argv[2]
outFile <- argv[3]

d <- read.csv2( countFile ) %>%
	pivot_longer( cols = 1:2, names_to = "temp", values_to = "count" ) %>%
	filter( !is.na(count)) %>%
	mutate( temp = factor( temp, levels = c("X37","RT")))

# Subset samples
LmRT <- d$count[ d$temp == "RT" ]
Lm37 <- d$count[ d$temp != "RT" ]



# bootstrap fold-change RT/37; large sample size so percentile method is valid.
logOfMean <- function(x){
	return( log( mean( x) ))
}
lm.boot <- two.boot( LmRT, Lm37, logOfMean, R = 100000 )
ci <- exp(boot.ci( lm.boot, type="perc" )$percent[4:5])
print(ci)
estimate <- exp( logOfMean( LmRT ) - logOfMean( Lm37 ) )#exp( mean( log(LmRT+.5) ) - mean( log(Lm37+.5) ) ) 
print(estimate)

dboot <- data.frame( x = 3, y = exp(lm.boot$t) * mean(Lm37) )
plotColors <- c( "X37" = "gray", "RT" = "black" )

Lm37exp <- expression( "Lm"^"Mu"*" 37" )
LmRTexp <- expression( "Lm"^"Mu"*" RT" )

# plot
pCount <- ggplot( d, aes( x = as.numeric(temp), y = count ) ) +
	annotate( "segment", x = 1, xend = 3, y = mean( Lm37), yend = mean( Lm37), 
		size = .3, color = plotColors["X37"], lty = 2 )+
	annotate( "segment", x = 2, xend = 3, y = mean( LmRT), yend = mean( LmRT), 
		size = .3, color = plotColors["RT"], lty = 2 )+
	#geom_hline( yintercept = mean( Lm37 ), size = 0.3, color = plotColors["X37"], lty = 2 ) +
	#geom_hline( yintercept = mean( LmRT ), size = 0.3, color = plotColors["RT"], lty = 2 ) +
	geom_quasirandom( size = .5, aes( color = temp ), show.legend = FALSE ) +
	geom_violinhalf( data = dboot, aes( x = x, y = y ), color = NA, fill = "forestgreen", alpha = .5, flip = TRUE ) +
	annotate( "segment", x = 3, xend = 3, y = ci[1] * mean(Lm37 ), yend = ci[2] * mean(Lm37 ) ) +
	annotate( "point", x = 3, y = estimate * mean(Lm37 ) ) +
	labs( x = NULL, y = "Estimated Lm#" ) +
	coord_cartesian( ylim = c(-5,1000), xlim = c(0.5,3.1), expand = FALSE ) +
	scale_y_continuous( 
		sec.axis = sec_axis(~( ./ mean(Lm37)), name = "Fold-change in #Lm (w.r.t. Lm-37)",
			breaks = c(1,25,50) ) ) +
	scale_x_continuous( breaks = c(1,2), labels = c(Lm37exp, LmRTexp) ) +
	
	scale_color_manual( values = plotColors ) +
	mytheme +
	theme( axis.line = element_blank() )
	


# ========== CFU Plots
	
d2 <- read.csv2( cfuFile ) %>%
	pivot_longer( cols = 1:2, names_to = "temp", values_to = "cfu" ) %>%
	filter( !is.na(cfu)) %>%
	mutate( temp = factor( temp, levels = c("X37","RT")))

	
# Subset samples
LmRT2 <- d2$cfu[ d2$temp == "RT" ]
Lm372 <- d2$cfu[ d2$temp != "RT" ]


geomean <- function(x){
	return( exp( mean(log(x))))
}

# bootstrap mean RT - mean 37; large sample size so percentile method is valid.
lm.boot2 <- two.boot( log( LmRT2 ), log( Lm372 ), mean, R = 100000 )
ci2 <- (boot.ci( lm.boot2, type="perc" )$percent[4:5])
print(exp(ci2))
estimate2 <- exp( mean( log( LmRT2 ) ) - mean( log( Lm372 ) ) )
print(estimate2)
dboot2 <- data.frame( x = 3, y = exp( (lm.boot2$t ) + mean(log(Lm372)) ) )


# plot
pCFU <- ggplot( d2, aes( x = as.numeric(temp), y = (cfu) ) ) +
	annotate( "segment", x = 1, xend = 3, y = geomean( Lm372), yend = geomean( Lm372), 
		size = .3, color = plotColors["X37"], lty = 2 )+
	annotate( "segment", x = 2, xend = 3, y = geomean( LmRT2), yend = geomean( LmRT2), 
		size = .3, color = plotColors["RT"], lty = 2 )+
	#geom_hline( yintercept = geomean(Lm372), size = 0.3, color = plotColors["X37"], lty = 2 ) +
	#geom_hline( yintercept = geomean(LmRT2), size = 0.3, color = plotColors["RT"], lty = 2 ) +
	geom_quasirandom( size = .5, aes( color = temp ), show.legend = FALSE ) +
	geom_violinhalf( data = dboot2, aes( x = x, y = y ), color = NA, fill = "forestgreen", alpha = .5, flip = TRUE ) +
	annotate( "segment", x = 3, xend = 3, y = exp( ci2[1] + mean(log(Lm372)) ), yend = exp( ci2[2] + mean( log( Lm372) ) ) ) +
	annotate( "point", x = 3, y = geomean(LmRT2) ) +
	labs( x = NULL, y = "CFU" ) +
	scale_y_log10( 
		sec.axis = sec_axis(~exp( log(.) - mean(log(Lm372)) ), name = "Fold-change in CFU (w.r.t Lm-37)" ,
		breaks = (c(1,2,10,50) ) ) ) +
	scale_x_continuous( breaks = c(1,2), labels = c(Lm37exp, LmRTexp) ) +
	coord_cartesian( ylim = c(500,10^7), xlim = c(0.5,3.1), expand = FALSE ) +
	scale_color_manual( values = plotColors ) +
	mytheme +
	theme( axis.line = element_blank() )






	
p <- pCount + pCFU + plot_layout( ncol = 1 )	
	
	
ggsave( outFile, plot = p, width = 5.5, height = 9.2, units = "cm" )
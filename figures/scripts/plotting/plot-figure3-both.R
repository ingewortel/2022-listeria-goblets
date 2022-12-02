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

earlyFile <- argv[1]
lateFile <- argv[2]
outFile <- argv[3]

d <- read.csv2( earlyFile ) %>%
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
ci <- exp( boot.ci( lm.boot, type="perc" )$percent[4:5] )
print(ci)
estimate <- exp( logOfMean( LmRT ) - logOfMean( Lm37 ) )
print(estimate)

dboot <- data.frame( x = 3, y = exp(lm.boot$t) * mean(Lm37) )
plotColors <- c( "X37" = "gray", "RT" = "black" )

Lm37exp <- "Lm-37" 
LmRTexp <- "Lm-RT" 

# plot
# pEarly <- ggplot( d, aes( x = as.numeric(temp), y = count ) ) +
# 	geom_hline( yintercept = mean( Lm37 ), size = 0.3, color = plotColors["X37"], lty = 2 ) +
# 	geom_hline( yintercept = mean( LmRT ), size = 0.3, color = plotColors["RT"], lty = 2 ) +
# 	geom_quasirandom( size = .5, aes( color = temp ), show.legend = FALSE ) +
# 	geom_violinhalf( data = dboot, aes( x = x, y = y ), color = NA, fill = "dodgerblue", alpha = .5, flip = TRUE ) +
# 	annotate( "segment", x = 3, xend = 3, y = ci[1] + mean(Lm37 ), yend = ci[2] + mean(Lm37 ) ) +
# 	annotate( "point", x = 3, y = estimate + mean(Lm37 ) ) +
# 	labs( x = NULL, y = "Estimated Lm#", title = "10 min" ) +
# 	scale_y_continuous( 
# 		sec.axis = sec_axis(~ . - mean(Lm37), name = "Difference in means" ) ) +
# 	scale_x_continuous( breaks = c(1,2), labels = c(Lm37exp, LmRTexp) ) +
# 	coord_cartesian( ylim = c(-1,70), xlim = c(0.5,3.1), expand = FALSE ) +
# 	scale_color_manual( values = plotColors ) +
# 	mytheme +
# 	theme( 
# 		axis.line = element_blank(),
# 		plot.title = element_text(vjust=-2) 
# 	)
pEarly <- ggplot( d, aes( x = as.numeric(temp), y = count ) ) +
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
	labs( x = NULL, y = "Estimated Lm#", title = "10 min" ) +
	coord_cartesian( ylim = c(-1,80), xlim = c(0.5,3.1), expand = FALSE ) +
	scale_y_continuous( 
		sec.axis = sec_axis(~( . / mean(Lm37)), name = "Fold-change (#Lm w.r.t. Lm-37)",
			breaks = c(1,25,50,75) ) ) +
	scale_x_continuous( breaks = c(1,2), labels = c(Lm37exp, LmRTexp) ) +
	
	scale_color_manual( values = plotColors ) +
	mytheme +
	theme( axis.line = element_blank(), plot.title = element_text(vjust=-2)  )	

	
d2 <- read.csv2( lateFile ) %>%
	pivot_longer( cols = 1:2, names_to = "temp", values_to = "count" ) %>%
	filter( !is.na(count)) %>%
	mutate( temp = factor( temp, levels = c("X37","RT")))

# Subset samples
LmRT2 <- d2$count[ d2$temp == "RT" ]
Lm372 <- d2$count[ d2$temp != "RT" ]

# bootstrap mean RT - mean 37; large sample size so percentile method is valid.
lm.boot2 <- two.boot( LmRT2, Lm372, logOfMean, R = 100000 )
ci2 <- exp( boot.ci( lm.boot2, type="perc" )$percent[4:5] )
print(ci2)
estimate2 <- exp( logOfMean( LmRT2 ) - logOfMean( Lm372 ) )
print(estimate2)
dboot2 <- data.frame( x = 3, y = exp(lm.boot2$t ) * mean(Lm372) )


# plot
pLate <- ggplot( d2, aes( x = as.numeric(temp), y = count ) ) +
	annotate( "segment", x = 1, xend = 3, y = mean( Lm372), yend = mean( Lm372), 
		size = .3, color = plotColors["X37"], lty = 2 )+
	annotate( "segment", x = 2, xend = 3, y = mean( LmRT2), yend = mean( LmRT2), 
		size = .3, color = plotColors["RT"], lty = 2 )+
	#geom_hline( yintercept = mean( Lm372 ), size = 0.3, color = plotColors["X37"], lty = 2 ) +
	#geom_hline( yintercept = mean( LmRT2 ), size = 0.3, color = plotColors["RT"], lty = 2 ) +
	geom_quasirandom( size = .5, aes( color = temp ), show.legend = FALSE ) +
	geom_violinhalf( data = dboot2, aes( x = x, y = y ), color = NA, fill = "forestgreen", alpha = .5, flip = TRUE ) +
	annotate( "segment", x = 3, xend = 3, y = ci2[1] * mean(Lm372 ), yend = ci2[2] * mean(Lm372 ) ) +
	annotate( "point", x = 3, y = estimate2 * mean(Lm372 ) ) +
	labs( x = NULL, y = "Estimated Lm#", title = "45 min" ) +
	scale_y_continuous( 
		sec.axis = sec_axis(~ . / mean(Lm372), name = "Fold-change (#Lm w.r.t. Lm-37)" ,
			breaks = c(1,10,20,30,40)) ) +
	scale_x_continuous( breaks = c(1,2), labels = c(Lm37exp, LmRTexp) ) +
	coord_cartesian( ylim = c(-2,120), xlim = c(0.5,3.1), expand = FALSE ) +
	scale_color_manual( values = plotColors ) +
	mytheme +
	theme( 
		axis.line = element_blank(),
		plot.title = element_text(vjust=-2) 
	)
	
	
p <- pEarly + pLate + plot_layout( ncol = 1 )	
	
	
ggsave( outFile, plot = p, width = 5.5, height = 9.5, units = "cm" )
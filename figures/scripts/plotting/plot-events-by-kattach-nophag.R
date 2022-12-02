library( ggplot2 )
library( dplyr, warn.conflicts = FALSE )
source("../scripts/plotting/mytheme.R")
library( patchwork )


argv <- commandArgs( trailingOnly = TRUE )

inFile <- argv[1]
totalGoblets <- as.numeric( argv[2] )
outFile <- argv[3]


areaGoblets <- 20/289
areaPhagocytes <- 14*315/(250*250)


d <- readRDS( inFile )
nBac <- unique( d$b )
plotColors <- c( "sLm-37" = "gray", "sLm-RT" = "dodgerblue3" )


# Compute averages and SDs/SEs
se <- function(x){
	n <- length(x)
	return( sd(x)/sqrt(n))
}
dMean <- d %>%
	filter( t == 3600 ) %>%
	mutate( temp = ifelse( x == 0, "sLm-37", "sLm-RT" ), a = 1000*a ) %>%
	group_by( temp, a ) %>%
	filter( is.element(t,c(300,3600)) ) %>%
	summarise(
		sd_inf = se( infection ),
		sd_ph = se( phagocytosis ),
		sd_gob = se( nGoblets ),
		mu_inf = mean(infection), 
		mu_ph = mean( phagocytosis ),
		mu_gob = mean( nGoblets ),
		pmu_inf = 100*mu_inf/b,
		pmu_ph = 100*mu_ph/b,
		pmu_gob = 100*mu_gob/totalGoblets,
		psd_inf = 100*sd_inf/b,
		psd_ph = 100*sd_ph/b,
		psd_gob = 100*sd_gob/totalGoblets
	)


tVec <- sort(unique(dMean$t))

# Make the plots
pInf <- ggplot( dMean, aes( x = a, y = mu_inf, color = temp, group = temp, fill = temp  ) ) +
	annotate("rect", xmin=0, xmax=10, ymin=0 , ymax=100, alpha=0.25, color=NA, fill="gray") +
	geom_hline( yintercept = 100*areaGoblets, lty = 2, size = 0.25, color = "gray30" ) +
	geom_ribbon( aes( ymin = mu_inf-sd_inf, ymax = mu_inf+sd_inf ), alpha = 0.25, color=NA, show.legend=FALSE ) +
	geom_line(show.legend=FALSE) +
	geom_point( show.legend=FALSE, size = .5 ) +
	coord_cartesian( xlim=c(0,NA), ylim=c(0,102), expand = FALSE ) +
	#scale_x_log10( limits=c(1,NA), expand=c(0,0))+
	#scale_y_continuous( limits=c(0,nBac), expand=c(0,0))+
	scale_color_manual( values =  plotColors) +
	scale_fill_manual( values = plotColors ) +
	labs( x = NULL, y = "% sLm invaded", title = "Invasion" ) +
	mytheme 


pGob <- ggplot( dMean, aes( x = a, y = pmu_gob, color = temp, group = temp, fill = temp   ) ) +
	annotate("rect", xmin=0, xmax=10, ymin=0 , ymax=100, alpha=0.25, color=NA, fill="gray") +
	geom_ribbon( aes( ymin = pmu_gob-psd_gob, ymax = pmu_gob+psd_gob ), alpha = 0.25, color=NA,show.legend=FALSE ) +
	geom_line() +
	geom_point( show.legend=FALSE, size = .5 ) +
	coord_cartesian( xlim=c(0,NA), ylim=c(0,102), expand = FALSE ) +
	#scale_x_log10( limits=c(1,NA), expand=c(0,0))+
	#scale_y_continuous( limits=c(0,20), expand=c(0,0))+
	scale_color_manual( values =  plotColors) +
	scale_fill_manual( values = plotColors ) +
	labs( x = NULL, y = "% targets infected", title = "Targets infected", color = NULL ) +
	mytheme

pInfZoom <- pInf + 
	coord_cartesian( xlim=c(0,10.2), ylim=c(0,102), expand = FALSE ) +
 	labs( x = expression( "k"["attach"]~"(x 1000 sec"^"-1"*")") , title = "") #expression( "Lm speed ("*mu*"m/sec)" )


pGobZoom <- pGob + 
	coord_cartesian( xlim=c(0,10.2), ylim=c(0,102), expand = FALSE )  +
 	labs( x = expression( "k"["attach"]~"(x 1000 sec"^"-1"*")"), title = "") +
 	theme( 
 		legend.position = "none"
 	)


des <- "AB
CD"

p <- pInf +pGob + pInfZoom + pGobZoom +
	plot_layout( design = des ) 

ggsave( outFile, useDingbats = FALSE, width = 11, height = 8, units = "cm" )

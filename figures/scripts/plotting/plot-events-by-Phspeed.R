library( ggplot2 )
library( dplyr, warn.conflicts = FALSE )
source("../scripts/plotting/mytheme.R")
library( patchwork )



argv <- commandArgs( trailingOnly = TRUE )

dataFile <- argv[1]
controlFile <- argv[2]
outFile <- argv[3]

d0 <- readRDS( controlFile ) %>%
	filter( t == max(t) )


d1 <- readRDS( dataFile ) %>%
	filter( t == max(t), x == 40 ) %>%
	mutate( l = 400, m = 20 )

d <- rbind( d0, d1 ) %>%
	mutate( phagocytes = ifelse( l == 0, "non-motile", "motile" ) )
	
nBac <- max(d$b)
totalGoblets <- 20

# Get Summary stats
se <- function(x){
	n <- length(x)
	return( sd(x)/sqrt(n))
}

# Compute averages and SDs
dMean <- d %>%
	group_by( v, phagocytes ) %>%
	summarise(
		sd_inf = se( infection ),
		sd_ph = se( phagocytosis ),
		sd_gob = se( nGoblets ),
		mu_inf = mean(infection), 
		mu_ph = mean( phagocytosis ),
		mu_gob = mean( nGoblets ),
		pmu_inf = 100*mu_inf/nBac,
		pmu_ph = 100*mu_ph/nBac,
		pmu_gob = 100*mu_gob/totalGoblets,
		psd_inf = 100*sd_inf/nBac,
		psd_ph = 100*sd_ph/nBac,
		psd_gob = 100*sd_gob/totalGoblets
	)

# Make the plots

plotColors <- c( "non-motile" = "gray40", "motile" = "maroon3" )

pInf <- ggplot( dMean, aes( x = v, y = pmu_inf, color = phagocytes, group = phagocytes, fill = phagocytes  ) ) +
	annotate("rect", xmin=0, xmax=20, ymin=0 , ymax=100, alpha=0.25, color=NA, fill="gray") +
	geom_ribbon( aes( ymin = pmu_inf-psd_inf, ymax = pmu_inf+psd_inf ), alpha = 0.25, color=NA, show.legend=FALSE ) +
	geom_line(show.legend=FALSE) +
	geom_point( show.legend=FALSE, size = .5 ) +
	scale_x_continuous( expand=c(0,0),limits=c(0,NA) ) +
	scale_y_continuous( limits=c(0,nBac), expand=c(0,0) ) +
	scale_color_manual( values =  plotColors) +
	scale_fill_manual( values = plotColors ) +
	labs( x = NULL, y = "% sLm invaded", title = "Invasion" ) +
	mytheme +
	theme( 
		legend.position=c(1,1),
		legend.justification =c(1,1)
	)

pPh <- ggplot( dMean, aes( x = v, y = pmu_ph, color = phagocytes, group = phagocytes, fill = phagocytes  ) ) +
	annotate("rect", xmin=0, xmax=20, ymin=0 , ymax=100, alpha=0.25, color=NA, fill="gray") +
	geom_ribbon( aes( ymin = pmu_ph-psd_ph, ymax = pmu_ph+psd_ph ), alpha = 0.25, color=NA,show.legend=FALSE ) +
	geom_line(show.legend=FALSE) +
	geom_point(show.legend=FALSE, size = .5) +
	scale_x_continuous( expand=c(0,0),limits=c(0,NA) ) +
	scale_y_continuous( limits=c(0,nBac), expand=c(0,0) ) +
	scale_color_manual( values =  plotColors) +
	scale_fill_manual( values = plotColors ) +
	labs( x = NULL, y = "% sLm phagocytosed", title = "Phagocytosis" ) +
	mytheme 


pGob <- ggplot( dMean, aes( x = v, y = pmu_gob, color = phagocytes, group = phagocytes, fill = phagocytes  ) ) +
	annotate("rect", xmin=0, xmax=20, ymin=0 , ymax=100, alpha=0.25, color=NA, fill="gray") +
	geom_ribbon( aes( ymin = pmu_gob-psd_gob, ymax = pmu_gob+psd_gob ), alpha = 0.25, color=NA,show.legend=FALSE ) +
	geom_line() +
	geom_point(show.legend=FALSE, size = .5) +
	scale_x_continuous( expand=c(0,0),limits=c(0,NA) ) +
	scale_y_continuous( limits=c(0,100), expand=c(0,0) ) +
	scale_color_manual( values =  plotColors) +
	scale_fill_manual( values = plotColors ) +
	labs( x = NULL, y = "% targets infected", title = "Targets infected", color = "phagocytes" ) +
	mytheme 

pInfZoom <- pInf + coord_cartesian( xlim=c(0,20), ylim=c(0,100), expand = FALSE ) +
	labs( x = "sLm relative speed (steps/s)", title = "")

pPhZoom <- pPh + coord_cartesian( xlim=c(0,20), ylim=c(0,100), expand = FALSE )  +
	labs( x = "sLm relative speed (steps/s)", title = "")

pGobZoom <- pGob + coord_cartesian( xlim=c(0,20), ylim=c(0,100), expand = FALSE )  +
	labs( x = "sLm relative speed (steps/s)", title = "") +
	theme( 
		legend.position = "none"
	)


p <- pInf + pPh + pGob + pInfZoom + pPhZoom + pGobZoom +
	plot_layout( ncol = 3 ) 

ggsave( outFile, useDingbats = FALSE, width = 16, height = 8, units = "cm" )





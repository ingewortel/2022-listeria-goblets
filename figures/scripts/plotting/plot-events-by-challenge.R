library( ggplot2 )
library( dplyr, warn.conflicts = FALSE )
library( tidyr )
source("../scripts/plotting/mytheme.R")
library( patchwork )


argv <- commandArgs( trailingOnly = TRUE )

inFile <- argv[1]
totalGoblets <- as.numeric( argv[2])
nBaseline <- as.numeric( argv[3] )
outFile <- argv[4]


d <- readRDS( inFile )

plotColors <- c( "sLm-37" = "gray", "sLm-RT" = "dodgerblue3" )
fateColors <- c( "invaded" = "gray30", "phagocytosed" = "maroon3" )

mytheme <- mytheme + theme( 
	legend.key.height = unit(3, 'mm'),
	legend.key = element_rect(colour = NA, fill = NA),
	legend.position = c(0.02,0),
	legend.justification = c(0,0)
)


# Compute means and SDs/SEs
se <- function(x){
	n <- length(x)
	return( sd(x)/sqrt(n))
}
dMean <- d %>%
	filter( t == 3600 ) %>%
	mutate( temp = ifelse( x == 0, "sLm-37", "sLm-RT" ) ) %>%
	group_by( temp, b ) %>%
	summarise(
		sd_inf = sd( infection ),
		sd_ph = sd( phagocytosis ),
		sd_gob = sd( nGoblets ),
		mu_inf = mean(infection), 
		mu_ph = mean( phagocytosis ),
		mu_gob = mean( nGoblets ),
		pmu_inf = 100*mu_inf/b[1],
		pmu_ph = 100*mu_ph/b[1],
		pmu_gob = 100*mu_gob/totalGoblets,
		psd_inf = 100*sd_inf/b[1],
		psd_ph = 100*sd_ph/b[1],
		psd_gob = 100*sd_gob/totalGoblets
	)

# Make the plots
pInf <- ggplot( dMean, aes( x = b, y = pmu_inf, color = temp, group = temp, fill = temp  ) ) +
	geom_vline( xintercept = nBaseline, color = "gray", size = 0.25, lty = 2 ) +
	geom_ribbon( aes( ymin = pmu_inf-psd_inf, ymax = pmu_inf+psd_inf ), alpha = 0.25, color=NA, show.legend=FALSE ) +
	geom_line(show.legend=FALSE) +
	geom_point( show.legend=FALSE, size = .5 ) +
	coord_cartesian( xlim=c(0,NA), ylim=c(0,100), expand = FALSE ) +
	scale_color_manual( values =  plotColors) +
	scale_fill_manual( values = plotColors ) +
	labs( x = expression( "# sLm challenged" ), y = "% sLm invaded", title = "Invasion", color = NULL ) +
	mytheme +
	theme( 
		legend.position=c(1,1),
		legend.justification =c(1,1)
	)

pPh <- ggplot( dMean, aes( x = b, y = pmu_ph, color = temp, group = temp, fill = temp  ) ) +
	geom_vline( xintercept = nBaseline, color = "gray", size = 0.25, lty = 2 ) +
	geom_ribbon( aes( ymin = pmu_ph-psd_ph, ymax = pmu_ph+psd_ph ), alpha = 0.25, color=NA,show.legend=FALSE ) +
	geom_line(show.legend=FALSE) +
	geom_point( show.legend=FALSE, size = .5 ) +
	coord_cartesian( xlim=c(0,NA), ylim=c(0,100), expand = FALSE ) +
	scale_color_manual( values =  plotColors) +
	scale_fill_manual( values = plotColors ) +
	labs( x = expression( "# sLm challenged" ), y = "% sLm phagocytosed", title = "Phagocytosis", color = NULL ) +
	mytheme 


pGob <- ggplot( dMean, aes( x = b, y = pmu_gob, color = temp, group = temp, fill = temp  ) ) +
	geom_vline( xintercept = nBaseline, color = "gray", size = 0.25, lty = 2 ) +
	geom_ribbon( aes( ymin = pmu_gob-psd_gob, ymax = pmu_gob+psd_gob ), alpha = 0.25, color=NA,show.legend=FALSE ) +
	geom_line() +
	geom_point( show.legend=FALSE, size = .5 ) +
	coord_cartesian( xlim=c(0,NA), ylim=c(0,100), expand = FALSE ) +
	scale_color_manual( values =  plotColors) +
	scale_fill_manual( values = plotColors ) +
	labs( x = expression( "# sLm challenged" ), y = "% targets infected", title = "Targets infected", color = NULL ) +
	mytheme 


# Also make the plot of invasion and phagocytosis in one plot for Lm-RT only.
dMeanRT <- dMean %>% 
	filter( temp == "sLm-RT" ) %>%
	select( temp, b, pmu_inf, pmu_ph, psd_inf, psd_ph ) %>% 
	pivot_longer( cols = 3:6, names_to = c(".value", "type"), names_pattern = "(.*)_(.*)" )
lookUp <- c( "inf" = "invaded", "ph" = "phagocytosed" )
dMeanRT$type <- lookUp[ dMeanRT$type ] 

pRT <- ggplot( dMeanRT, aes( x = b, y = pmu, color = type, group = type, fill = type  ) ) +
	geom_vline( xintercept = nBaseline, color = "gray", size = 0.25, lty = 2 ) +
	geom_ribbon( aes( ymin = pmu-psd, ymax = pmu+psd ), alpha = 0.25, color=NA,show.legend=FALSE ) +
	geom_line() +
	geom_point( show.legend=FALSE, size = .5 ) +
	coord_cartesian( xlim=c(0,NA), ylim=c(0,100), expand = FALSE ) +
	scale_color_manual( values =  fateColors) +
	scale_fill_manual( values = fateColors ) +
	labs( x = expression( "# sLm challenged" ), y = "% sLm", title = "sLm-RT fate", color = NULL ) +
	mytheme 

p <- pInf + pPh + pGob + pRT +
	plot_layout( ncol = 4 ) 

ggsave( outFile, useDingbats = FALSE, width = 18, height = 5, units = "cm" ) #w16

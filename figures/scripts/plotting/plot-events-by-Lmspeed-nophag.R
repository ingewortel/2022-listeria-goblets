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

# First compare the v=1, lambda_dir = 40 vs v=1, lambda_dir = 0 scenario where bacteria
# should not be moving (too much)
d0 <- d %>% 
	filter( v == 1 ) %>%
	mutate( x = as.factor(x) ) 

d0Mean <- d0 %>%
	group_by( x, t ) %>%
	summarise( 
		sd_inf = sd( infection ),
		sd_ph = sd( phagocytosis ),
		mu_inf = mean(infection), 
		mu_ph = mean( phagocytosis )
	)


# Now remove the v= 1, lambda_dir = 0 so that everything has lambda_dir = 40.
d2 <- d %>%
	filter( x > 0 )

# Compute averages and SDs/SEs
se <- function(x){
	n <- length(x)
	return( sd(x)/sqrt(n))
}
dMean <- d2 %>%
	group_by( v, t ) %>%
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
pInf <- ggplot( dMean, aes( x = v, y = mu_inf, color = t, group = t, fill = t  ) ) +
	annotate("rect", xmin=0, xmax=10, ymin=0 , ymax=100, alpha=0.25, color=NA, fill="gray") +
	geom_hline( yintercept = 100*areaGoblets, lty = 2, size = 0.25, color = "gray30" ) +
	geom_ribbon( aes( ymin = mu_inf-sd_inf, ymax = mu_inf+sd_inf ), alpha = 0.25, color=NA, show.legend=FALSE ) +
	geom_line(show.legend=FALSE) +
	geom_point( show.legend=FALSE, size = .5 ) +
	coord_cartesian( xlim=c(-2,NA), ylim=c(0,102), expand = FALSE ) +
	#scale_x_log10( limits=c(1,NA), expand=c(0,0))+
	#scale_y_continuous( limits=c(0,nBac), expand=c(0,0))+
	scale_color_gradient( breaks = tVec, 
		guide = guide_legend( keyheight = 0.4, default.unit = "cm" ),
		labels = tVec ) +
	labs( x = NULL, y = "% sLm invaded", title = "Invasion" ) +
	mytheme 


pGob <- ggplot( dMean, aes( x = v, y = pmu_gob, color = t/60, group = t/60, fill = t/60  ) ) +
	annotate("rect", xmin=0, xmax=10, ymin=0 , ymax=100, alpha=0.25, color=NA, fill="gray") +
	geom_ribbon( aes( ymin = pmu_gob-psd_gob, ymax = pmu_gob+psd_gob ), alpha = 0.25, color=NA,show.legend=FALSE ) +
	geom_line() +
	geom_point( show.legend=FALSE, size = .5 ) +
	coord_cartesian( xlim=c(-2,NA), ylim=c(0,102), expand = FALSE ) +
	#scale_x_log10( limits=c(1,NA), expand=c(0,0))+
	#scale_y_continuous( limits=c(0,20), expand=c(0,0))+
	scale_color_gradient( breaks = tVec/60, 
		guide = guide_legend( keyheight = 0.27, default.unit = "cm" ),
		labels = tVec/60 ) +
	labs( x = NULL, y = "% targets infected", title = "Targets infected", color = "time (min)" ) +
	mytheme

pInfZoom <- pInf + coord_cartesian( xlim=c(-0.1,10), ylim=c(0,102), expand = FALSE ) +
	labs( x = "sLm relative speed (steps/sec)" , title = "") #expression( "Lm speed ("*mu*"m/sec)" )


pGobZoom <- pGob + coord_cartesian( xlim=c(-0.1,10), ylim=c(0,102), expand = FALSE )  +
	labs( x = "sLm relative speed (steps/sec)", title = "") +
	theme( 
		legend.position = "none"
	)


des <- "AB
CD"

p <- pInf +pGob + pInfZoom + pGobZoom +
	plot_layout( design = des ) 

ggsave( outFile, useDingbats = FALSE, width = 11, height = 8, units = "cm" )

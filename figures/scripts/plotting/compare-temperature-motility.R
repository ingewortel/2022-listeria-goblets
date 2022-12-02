library( celltrackR )
suppressMessages( library( dplyr ) )
library( ggplot2 )
library( ggbeeswarm )
library( patchwork )
library( geomtextpath )
source("../scripts/plotting/prettylog.R")
source("../scripts/plotting/mytheme.R")
source("../scripts/analysis/msd-fitting-functions.R")
source("../scripts/analysis/acov-fitting-functions.R")
source("../scripts/analysis/deltaBIC.R")

plotColors <- c( "Lm-37" = "gray60", "Lm-RT" = "black", "Lm-RT-m" = "forestgreen" ) # dodgerblue3

#Lm-37

argv <- commandArgs( trailingOnly = TRUE )

file37 <- argv[1]
fileRT <- argv[2]
fileBootstrapRT <- argv[3]
fileBootstrapRTm <- argv[4]
fileStepsRTm <- argv[5]
outPlot <- argv[6]

tracks37 <- readRDS( file37 )
tracksRT <- readRDS( fileRT )


# Compare cell-based speeds
speed37 <- data.frame( temp = "Lm-37", speed = sapply( tracks37, speed ), dBIC = sapply( tracks37, deltaBIC )  ) %>%
	mutate( top = "yes" )
speedRT <- data.frame( temp = "Lm-RT", speed = sapply( tracksRT, speed ), dBIC = sapply( tracksRT, deltaBIC ) ) %>%
	mutate( top = ifelse( dBIC >= 0, "yes","no" ) )
speedRTm <- speedRT %>% filter( dBIC >= 0 ) %>% mutate( temp = "Lm-RT-m" )
speedData <- rbind( speed37, speedRT, speedRTm )
speedMeans <- speedData %>% group_by( temp ) %>% summarise( mu = mean(speed) )

yrange <- c(-2, ceiling(max(log10(speedData$speed*2))) ) # in log

# plot mean speed per track and show the population mean of the (untransformed) speeds,
# but show on a log scale to see the difference. 
pSpeedNormal <- ggplot( speedData, aes( x = temp, y = speed, color = temp ) ) + 
	geom_quasirandom( aes( alpha = top ), size = 0.1, shape = 16, show.legend = FALSE ) +
	#geom_hline( alpha = 0.5, data = speedMeans, aes( yintercept = mu, color = temp ), lty = 1, size = 0.25, show.legend = FALSE ) +
	geom_segment( data = speedMeans, 
                size = 0.5,
                color = "black",
                aes( x = as.numeric(as.factor(temp))-0.3, 
                     xend = as.numeric(as.factor(temp)) + 0.3, 
                     y = mu, 
                     yend = mu ) )+
    scale_color_manual( values = plotColors ) +
    scale_alpha_manual( values = c( "yes" = 1, "no" = 0.2 ) ) +
	labs( x = NULL, y = expression( "track speed ("*mu*"m/s)")) +
	mytheme + theme(
		plot.margin = unit(c(0.1,0,0.1,0),"cm"),
		axis.text.x = element_text(size=5.5)
	)

pSpeedLog <- pSpeedNormal + scale_prettylog( "y", labellogs = seq( yrange[1], yrange[2] ), limits = 10^yrange )

# load bootstrapped mean difference and plot
muDiffRT <- data.frame( d = readRDS( fileBootstrapRT ) ) %>% mutate( group = "Lm-RT")
muDiffRTm <- data.frame( d = readRDS( fileBootstrapRTm ) ) %>% mutate( group = "Lm-RT-m")
muDiff <- rbind( muDiffRT, muDiffRTm )
CIs <- muDiff %>% group_by( group ) %>% 
	summarise( lower = quantile( d, 0.005 ), upper = quantile( d, 0.995 ), mean = mean(d) ) %>%
	mutate( group = factor( group, levels = c("Lm-RT", "Lm-RT-m")),
		label = group ) #paste0( group, "\n ", "-Lm-37") )

pDiff <- ggplot( CIs, aes( x = label, y = mean ) ) +
	geom_hline( yintercept = 0, lty = 1, size = 0.2, color = "gray60", alpha = 0.5 ) +
	geom_hline( data = CIs, aes( yintercept = mean, color = group ), lty = 1, size = 0.25, show.legend = FALSE, alpha = 0.5 ) +
	geom_errorbar( aes( ymin= lower, ymax = upper, color = group ), size = 0.3, width = 0.4 , show.legend = FALSE ) +
	#geom_point(size=0.2) +
	scale_y_continuous( limits=c(0,max(speedData$speed)), position ="right") +
	scale_color_manual( values = plotColors ) +
	#annotate( "text", x = 1.5, y = 30, label = expression( Delta*"mean (99%CI)"), size = 6*(5/14) ) +
	labs( y = expression( "mean - mean"["Lm-37"] ) ) +
	#annotate( "segment", x = "", xend = "", y = quantile( muDiffLm-RT$d, 0.025 ), yend = quantile( muDiffLm-RT$d, 0.975 ) ) +
	mytheme + 
	theme( 
		axis.title.x = element_blank(),
		axis.line.x = element_blank(),
		axis.ticks.x = element_blank(),
		panel.border = element_blank()
	) + theme(
		axis.text.x = element_blank(), #element_text(angle = 25, vjust = 1, hjust=1, size=5)
		plot.margin = unit(c(0.1,0.3,0.1,0),"cm")
	)




# Compare MSD
# getMSD() is in ../../scripts/analysis/msd-fitting-functions.R
msd37 <- getMSD( tracks37 ) %>% mutate( temp = "Lm-37" )
msdRT <- getMSD( tracksRT ) %>% mutate( temp = "Lm-RT" )
tracksRTm <- tracksRT[ speedRT$dBIC > 0 ]
msdRTm <- getMSD( tracksRTm ) %>% mutate( temp = "Lm-RT-m" )
msdAll <- rbind( msd37, msdRT, msdRTm ) %>% 
	mutate( temp = factor( temp, levels = c("Lm-37","Lm-RT","Lm-RT-m" ) ) ) %>%
	filter( fCells >= 0.5 )

pMSD <- ggplot( msdAll, aes ( x = dt, y = mean, group = temp, color = temp, fill = temp ) ) +
	geom_ribbon( aes( ymin = lower, ymax = upper ), alpha = 0.2, color = NA, show.legend = FALSE ) +
	#geom_line() +
	geom_textline( aes( label = temp ), size = 2, linewidth = .5, show.legend = FALSE ) + 
	scale_color_manual( values = plotColors ) +
	scale_fill_manual( values = plotColors ) +
	scale_x_continuous( limits = c(0,max( msdAll$dt[ msdAll$temp == "Lm-RT"])), expand = c(0,0) )+
	scale_y_continuous( limits = c(-50,NA), expand = c(0,0) ) +
	labs( x = expression( Delta*"t (sec)"),
		y  = expression( MSD*" ("*mu*"m"^2*")"),
		color = NULL, fill = NULL ) +
	mytheme 



# Compare Acov
# getAcov() is in ../../scripts/analysis/acov-fitting-functions.R
acov37 <- getAcov( tracks37, norm = TRUE ) %>% mutate( temp = "Lm-37" )
acovRT <- getAcov( tracksRT, norm = TRUE ) %>% mutate( temp = "Lm-RT" )
tracksRTm <- tracksRT[ speedRT$dBIC > 0 ]
acovRTm <- getAcov( tracksRTm, norm = TRUE ) %>% mutate( temp = "Lm-RT-m" )
acovAll <- rbind( acov37, acovRT, acovRTm ) %>% 
	mutate( temp = factor( temp, levels = c("Lm-37","Lm-RT","Lm-RT-m" ) ) ) %>%
	filter( fCells >= 0.5 )

pAcov <- ggplot( acovAll, aes ( x = dt, y = mean, group = temp, color = temp, fill = temp ) ) +
	geom_ribbon( aes( ymin = lower, ymax = upper ), alpha = 0.2, color = NA ) +
	geom_line() +
	scale_color_manual( values = plotColors ) +
	scale_fill_manual( values = plotColors ) +
	scale_x_continuous( limits = c(0,max( acovAll$dt[ acovAll$temp == "Lm-RT"])), expand = c(0,0) )+
	scale_y_continuous( limits = c(NA,NA), expand = c(0,0) ) +
	labs( x = expression( Delta*"t (s)"),
		y  = expression( Autocovariance*" ("*mu*"m"^2*")"),
		color = NULL, fill = NULL ) +
	mytheme + theme(
		legend.position = c(1,1),
		legend.justification = c(1,1)
	)


# Compare Angles
# getAngles() is in ../../scripts/analysis/acov-fitting-functions.R
ang37 <- getAngles( tracks37 ) %>% mutate( temp = "Lm-37" )
angRT <- getAngles( tracksRT ) %>% mutate( temp = "Lm-RT" )
tracksRTm <- tracksRT[ speedRT$dBIC > 0 ]
angRTm <- getAngles( tracksRTm ) %>% mutate( temp = "Lm-RT-m" )
angAll <- rbind( ang37, angRT, angRTm ) %>% 
	mutate( temp = factor( temp, levels = c("Lm-37","Lm-RT","Lm-RT-m" ) ) ) %>%
	filter( fCells >= 0.5 )

pAngles <- ggplot( angAll, aes ( x = dt, y = mean, group = temp, color = temp, fill = temp ) ) +
	geom_hline( yintercept = 90, lty = 2, size = 0.2 ) +
	geom_ribbon( aes( ymin = lower, ymax = upper ), alpha = 0.2, color = NA ) +
	geom_line() +
	scale_color_manual( values = plotColors ) +
	scale_fill_manual( values = plotColors ) +
	scale_x_continuous( limits = c(0,max( angAll$dt[ angAll$temp == "Lm-RT"])), expand = c(0,0) )+
	scale_y_continuous( limits = c(0,NA), expand = c(0,0) ) +
	labs( x = expression( Delta*"t (s)"),
		y  =  "turning angle (\u00B0)",
		color = NULL, fill = NULL ) +
	mytheme + theme(
		legend.position = c(1,0),
		legend.justification = c(1,0)
	)

# Crowding analysis: step distance vs angle (only for motile Lm-RT population)
stepPairs <- readRDS( fileStepsRTm ) %>% filter( dist <= 50 )
#stepSample <- slice_sample( stepPairs, prop=0.5 )
stepSample2 <- slice_sample( stepPairs, prop = 0.02 )
pCrowd <- ggplot( stepPairs, aes( x = dist, y = angle ) ) +
	scale_x_continuous( limits=c(0,50), expand=c(0,0)) +
	geom_point( data = stepSample2, color = "gray", size = 0.01 ) +
	stat_smooth( size = 0.3, fill = "dodgerblue3", color = "dodgerblue3" ) +
	labs( x = expression( "distance ("*mu*"m)"), y = "angle (\u00B0)") +
	geom_hline( yintercept = 90, size = 0.3, lty = 2, color = "red" ) +
	scale_y_continuous( limits=c(0,180), expand =c(0,0), breaks = seq(0,180,by=45))+
	mytheme



# TODO : Statistical test: likelihood ratio test.
# Need to compute the likelihoods under two models:
# 1) H0: come from the same distribution; fit all the data using one MSD fit
# 2) H1: come from a different distribution; fit both datasets separately
# But what is the PDF of the FuLm-RTh equation?
# Alternatively: bootstrapping - but bootstrap what?




design <- "
AAAABCCC
DDDDDEEE
"

p <- pSpeedNormal + pDiff + pMSD + pAngles + pCrowd +
	plot_layout( design = design ) 
ggsave( outPlot, width = 10, height = 6.5, units = "cm", useDingbats = FALSE )
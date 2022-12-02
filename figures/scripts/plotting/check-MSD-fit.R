library( celltrackR )
source( "../scripts/analysis/msd-fitting-functions.R" )
source( "../scripts/analysis/acov-fitting-functions.R" )
source("../scripts/plotting/mytheme.R")
library( ggplot2 )
library( patchwork )
suppressMessages( library( dplyr ) )
library( ggbeeswarm ) 

argv <- commandArgs( trailingOnly = TRUE )

tracks37 <- readRDS( argv[1] )
tracksRT <- readRDS( argv[2] )
tracksRTm <- readRDS( argv[3] )
parms37 <- readRDS( argv[4] )
parmsRT <- readRDS( argv[5] )
parmsRTm <- readRDS( argv[6] )
outFile <- argv[7]


makePlot <- function( tracks, furth = TRUE ){
	msd <- getMSD( tracks )
	fit <- fitMSD( msd, cutoff = 5 )
	p <- plotMSDfit( msd, fit, cutoff = 5, furth = furth ) + mytheme
	return(p) 
}

makeAcovPlot <- function( tracks, plotFit = TRUE ){
	acov <- getAcov( tracks )
	fit <- data.frame( tau = NA, A = NA )
	if( plotFit ) fit <- fitAcov( acov, cutoff = 5 )
	p <- plotAcovFit( acov, fit, cutoff = 5, plotFit = plotFit ) + mytheme
	return(p)
}


p37 <- makePlot( tracks37 ) + 
	labs( title = "Lm-37" )
	
pRT <- makePlot( tracksRT ) + 
	labs( title = "Lm-RT" )
	
pRTm <- makePlot( tracksRTm ) + 
	labs( title = "Lm-RT-m" )
	
p37b <- makeAcovPlot( tracks37, plotFit = FALSE )

pRTb <- makeAcovPlot( tracksRT )

pRTmb <- makeAcovPlot( tracksRTm )


# plots of bootstrapped estimated D and P
parms37 <- parms37 %>% mutate( data = "Lm-37" )
parmsRT <- parmsRT %>% mutate( data = "Lm-RT" )
parmsRTm <- parmsRTm %>% mutate( data = "Lm-RT-m" )
parms <- rbind( parms37, parmsRT, parmsRTm )
parmsMean <- parms %>% group_by( data ) %>% summarise( P = mean(P), D = mean(D) )

print(parmsMean)

pvaluesD <- signif( c( "RT-37" = t.test( parms37$D, parmsRT$D )$p.value, "RTm-37" = t.test( parms37$D, parmsRTm$D )$p.value ), digits=1)
pvaluesP <- signif( c( "RT-37" = t.test( parms37$P, parmsRT$P )$p.value, "RTm-37" = t.test( parms37$P, parmsRTm$P )$p.value ), digits=1)


pD <- ggplot( parms, aes( x = data, y = D ) ) +
	geom_violin( scale = "width", fill = "gray70", color = NA ) +
	geom_segment( data = parmsMean, 
                size = 0.5,
                color = "black",
                aes( x = as.numeric(as.factor(data))-0.3, 
                     xend = as.numeric(as.factor(data)) + 0.3, 
                     y = D, 
                     yend = D ) )+
	#annotate( "text", x = 1.5, y = max( parms$D[parms$data=="Lm-RT"]), label = paste0("p = ",pvaluesD["RT-37"]), vjust = -0.3, size = 6*(5/14))+
	#annotate( "text", x = 2.5, y = max( parms$D[parms$data=="Lm-RT-m"]), label = paste0("p = ",pvaluesD["RTm-37"]), vjust = -0.3, size = 6*(5/14))+
    #annotate( "segment", x = 1, xend = 2, y = max( parms$D[parms$data=="Lm-RT"]), yend = max( parms$D[parms$data=="Lm-RT"]), size = 0.2 ) +
    #annotate( "segment", x = 1, xend = 3, y = max( parms$D[parms$data=="Lm-RT-m"]), yend = max( parms$D[parms$data=="Lm-RT-m"]), size = 0.2 ) +
    labs( title = "estimate", y = expression( "M ("*mu*"m"^2*")")) +
    scale_y_continuous( limits = c(0,100)) +
	mytheme + theme(
		axis.title.x = element_blank()
	)

pP <- ggplot( parms, aes( x = data, y = P ) ) +
	geom_violin( scale = "width", fill = "gray70", color = NA ) +
	geom_segment( data = parmsMean, 
                size = 0.5,
                color = "black",
                aes( x = as.numeric(as.factor(data))-0.3, 
                     xend = as.numeric(as.factor(data)) + 0.3, 
                     y = P, 
                     yend = P ) )+
	#annotate( "text", x = 1.5, y = max( parms$P[parms$data=="Lm-RT"]), label = paste0("p = ",pvaluesP["RT-37"]), vjust = -0.3, size = 6*(5/14))+
	#annotate( "text", x = 2.5, y = max( parms$P[parms$data=="Lm-RT-m"]), label = paste0("p = ",pvaluesP["RTm-37"]), vjust = -0.3, size = 6*(5/14))+
	#annotate( "segment", x = 1, xend = 2, y = max( parms$P[parms$data=="Lm-RT"]), yend = max( parms$P[parms$data=="Lm-RT"]), size = 0.2 ) +
    #annotate( "segment", x = 1, xend = 3, y = max( parms$P[parms$data=="Lm-RT-m"]), yend = max( parms$P[parms$data=="Lm-RT-m"]), size = 0.2 ) +
	scale_y_continuous( limits = c(0,1.1*max(parms$P)))+
	labs( y = "P (s)" ) +
	mytheme + theme(
		axis.title.x = element_blank()
	)


 p <- p37 + pRT + pRTm + pD +
	p37b + pRTb + pRTmb + pP +
	plot_layout( ncol = 4, widths = c(3,3,3,4) )



suppressWarnings( ggsave( p, file = outFile, useDingbats = FALSE, width = 18, height = 8, units = "cm") )
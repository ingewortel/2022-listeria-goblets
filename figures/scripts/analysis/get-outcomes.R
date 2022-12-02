suppressMessages( library( dplyr ) ) 

argv <- commandArgs( trailingOnly = TRUE )

settingsFile <- argv[1]
directory <- argv[2]
expName <- argv[3]
nSim <- as.numeric( argv[4] )
outFile <- argv[5]

# Check at times: 5, 10, 30, 60 min
tvec <- 60* c( 5, 10, 30, 60 ) # in seconds

parms <- read.table( settingsFile, sep = "\t", header = TRUE )

getOutcomes <- function( parms, sim, endTime = max( df$V2 ) ){

	# get filename of current simulation based on parms and simnumber.
	parmString <- paste0( colnames(parms), parms, collapse="-" )
	fileString <- paste0( directory, "/", expName, "-", parmString, "-sim" )

	# read individual simulation file (everything but the last line)
	f <- paste0( fileString, sim, ".txt" )
	input <- rev( readLines( f) )[-1]

	if( length( input ) == 0 ) { 
		df <- data.frame( event = 0, t = 0, bact = 0, partner = 0 )[-1,]
	} else {
		df <- read.table( textConnection( rev( input ) ) )
		colnames( df ) <- c( "event", "t", "bact", "partner") 
	}

	if( nrow( df ) == 0 ){ 
		dfCount <- data.frame(
			infection = 0, phagocytosis = 0, attachment = 0, detachment = 0, goblets = 0,
			nGoblets = 0
		)
	} else {
		# filter based on time (second column)
		df <- df %>% filter( t <= endTime )
	
		# count how many of each event (infection/attachment/phagocytosis/...)
		counts <- table( df$event )

		if( length( counts ) == 0 ){
			dfCount <- data.frame( attachment = 0 )
		} else {

			# to dataframe of one row
			dfCount <- as.data.frame(counts) %>% 
				tidyr::pivot_wider( names_from = Var1, values_from = Freq ) 
	
		}

		# Separately: count the number of goblets infected and add
		dfCount$nGoblets <- df %>% 
			filter( event == "infection" ) %>%
			select( partner ) %>%
			summarise( partner = unique(partner)) %>%
			nrow()
			
	
		# add any missing columns
		for( cname in c("infection", "goblets", "attachment", "detachment", "phagocytosis")){
			if( !is.element( cname, colnames(dfCount))){
				dfCount[,cname] <- 0
			}
		}
	}


	# add sim number and time
	dfCount <- dfCount %>% mutate( sim = sim, t = endTime )
	
	# add parms
	dfCount <- cbind( dfCount, parms )
	
	return(dfCount)

}


dout <- data.frame()

for( i in 1:nrow(parms) ){

	for( tt in tvec ){
		dtmp <- bind_rows( lapply( 1:nSim, function(s){
			getOutcomes( parms[i,], s, endTime = tt )
		}) )
		1 
	
		if( nrow(dtmp) > 0 ){
			for( v in colnames(parms)){
				# Rescale some parameters (e.g. rates given as 1000x rates, correct to orig value)
				dtmp[[v]] <- ifelse( is.element( v, c("i","f","a")), parms[i,v]/1000, parms[i,v] )
			}
			dout <- rbind( dout, dtmp ) 
		} 
	
	}
		
}


saveRDS( dout, file = outFile )

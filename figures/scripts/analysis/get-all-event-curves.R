suppressMessages( library( dplyr ) ) 

argv <- commandArgs( trailingOnly = TRUE )

settingsFile <- argv[1]
directory <- argv[2]
expName <- argv[3]
nSim <- as.numeric( argv[4] )
outFile <- argv[5]

parms <- read.table( settingsFile, sep = "\t", header = TRUE )

eventCurve <- function( fileString, sim, filter.events=NULL, endTime = max( df$V2 ), nStart = 0, mode = "gain" ){

	# read individual simulation files (everything but the last line)
	f <- paste0( fileString, sim, ".txt" )
	empty <- (file.size(f) == 0L)
	if( empty ){
		return( data.frame() )
	}
	input <- rev( readLines( f) )[-1]
	df <- read.table( textConnection( rev( input ) ) )

	if( !is.null(filter.events) ){
		df <- df %>% filter( V1 == filter.events )
	}

	if( nrow( df ) == 0 ){ return( data.frame() ) }	

	# time (in MCS) is in the second column; event type in first.
	# (other columns are cellIDs of the bacterium + goblet cell target)
	times <- sort( df$V2 )
	
	# count how many events at each time point
	cumEscapes <- cumsum( table( times ) )

	# add first and last timepoint; add both the number before and after the events
	times <- c( 0, unique( times ), endTime )
	escBefore <- c( 0, 0, cumEscapes )
	escAfter <- c( 0, cumEscapes, cumEscapes[ length(cumEscapes) ] )
	
	if( mode == "gain" ){
		dout <- data.frame( tp = rep( times, 2 ), 
			n = nStart + c( escBefore, escAfter ) ) %>%
			arrange( n, tp )
	} else if( mode == "loss" ){
		dout <- data.frame( tp = rep( times, 2 ), 
			n = nStart - c( escBefore, escAfter ) ) %>%
			arrange( desc(n), tp )
	
	} else {
		stop( "please choose mode = 'gain' or 'loss'.")
	}

	dout <- dout %>% mutate( sim = sim )
	return(dout)

}


dout <- data.frame()

for( i in 1:nrow(parms) ){
	print(i)
	parmString <- paste0( colnames(parms), parms[i,], collapse="-" )
	fileString <- paste0( directory, "/", expName, "-", parmString, "-sim" )
	
	nStart <- parms$b[i]
	
	allSimsInf <- bind_rows( lapply( 1:nSim, function(s){ 
		eventCurve(fileString,s,"infection") %>% 
			mutate( type = "invaded" )  %>% 
			unique() %>%
			mutate( nStart = nStart )
	}) )
	allSimsAtt <- bind_rows( lapply( 1:nSim, function(s){
		eventCurve( fileString, s, "attachment" ) %>%
		mutate( type = "attached" ) %>%
		unique() %>%
		mutate( nStart = nStart )
	} ))
	
	allSimsPh <- bind_rows( lapply( 1:nSim, function(s){ 
		eventCurve(fileString,s,"phagocytosis" ) %>% 
			mutate( type = "phagocytosed" )  %>% 
			unique() %>%
			mutate( nStart = nStart )
	}) )
	
	dtmp <- rbind( allSimsInf, allSimsAtt, allSimsPh )
	
	if( nrow(dtmp) > 0 ){
		for( v in colnames(parms)){
			# Rescale some parameters (e.g. rates given as 1000x rates, correct to orig value)
			dtmp[[v]] <- ifelse( is.element( v, c("i","f","a")), parms[i,v]/1000, parms[i,v] )
		}
		dtmp <- dtmp %>%
			mutate( perc = 100*n/nStart )
		dout <- rbind( dout, dtmp ) 
	} 
		
}


saveRDS( dout, file = outFile )

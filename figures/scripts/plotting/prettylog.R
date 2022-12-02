scale_prettylog <- function( axis, minlog = NULL, maxlog = NULL, limits = NULL, labellogs = seq(minlog,maxlog), ticks = TRUE ){
	
	logs <- seq( min( labellogs), max(labellogs ))

	if( is.null(minlog) ){
		minlog <- min( labellogs )
	}
	if( is.null( maxlog) ){
		maxlog <- max( labellogs )
	}
	
	if( is.null(limits) ){
		limits <- c(10^minlog, 10^maxlog)
	}

	
	ax.breaks <- lapply( 1:(length(logs)-1), function(x){
		seq( 10^logs[x], 10^logs[x+1], by = 10^logs[x] ) 
	})
	
	ax.breaks <- unique( unlist( ax.breaks ) )
	ax.labels <- as.character( ax.breaks )
	lognum <- log10( as.numeric( ax.breaks ) )
	logtext <- paste( "10^", lognum )
	ax.labels <- sapply( logtext, function(x) parse( text = x ))
	
	#expression(  paste( "10^",  ) )
	#ax.labels <- expression( paste( "10^",lognum ) ) 
	#ax.labels[ ( seq_along( ax.breaks ) - 1 ) %% 9 != 0 ] <- ""
	ax.labels[ !is.element( lognum, labellogs) ] <- ""


	#return( list( breaks = ax.breaks, labels = ax.labels ) )
	
	if( axis == "x" ){
		return( scale_x_log10( breaks = ax.breaks, labels = ax.labels, 
			expand = c(0,0), limits = limits ) )
	} else if( axis == "y" ){
		return( scale_y_log10( breaks = ax.breaks, labels = ax.labels, 
			expand = c(0,0), limits = limits ) ) 
	} else {
		stop( "axis must be x or y!" )
	}
	
}
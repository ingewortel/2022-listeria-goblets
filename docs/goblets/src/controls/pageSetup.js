
	/* Changing the zoom level of the simulation */
	changeZoom = function( zoom ){
	
		zoomCanvas( CimEpi, zoom )
		zoomCanvas( CimAct, zoom )
		zoomCanvas( CimBact, zoom )
		zoomCanvas( CimInf, zoom )
		zoomContainer( "simulationContainer", zoom ) 
	}
	zoomCanvas = function( cim, zoom ){
		cim.zoom = zoom;
		cim.el.width = zoom*cim.C.extents[0]
		cim.el.height = zoom*cim.C.extents[1]
	}
	zoomContainer = function( container, zoom ){
		const ctn = document.getElementById( container )
		const w = CEpi.extents[0]*CimEpi.zoom, h = CEpi.extents[1]*CimEpi.zoom 
		//if( w <= ctn.style["max-width"] ) 
		ctn.style.width = w + "px"
		ctn.style.height = h  + 'px'
	}
	initZoom = function () {
		if (window.matchMedia('(max-width: 450px)').matches)
		{
			viz.zoom = 1
			zoomContainer( "simulationContainer", viz.zoom )
			changeZoom(viz.zoom)
		} else {
			zoomContainer( "simulationContainer", viz.zoom )
		}
		
	}
	// On resize, check if the screen has changed from wide <-> small and the sidebar
	// should change:
	$(window).resize(function (){
		if (window.matchMedia('(max-width: 450px)').matches)
		{
			zoom = 1
			changeZoom(zoom)
		} else {
			zoom = 2
			changeZoom(zoom)
		}
		
	});
	
	setPlayPause = function(){
		if( running ){
			$('#playIcon').removeClass('fa-play');$('#playIcon').addClass('fa-pause')
		} else {
			$('#playIcon').removeClass('fa-pause');$('#playIcon').addClass('fa-play')
		}	
	}
	
	$(document).ready(function () {
			
		$('#playPause').on('click', function () {
			toggleRunning()
			setPlayPause()		
		});
		$('#reset').on('click', function () {
			const currentSeed = document.getElementById("rseed").value
			conf.seed = currentSeed
			confBact.seed = currentSeed
			confAct.seed = currentSeed
			confEpi.seed = currentSeed
			resetSim()
			setPlayPause()
		});
	});
		
	
	setLambdaDirBacteria = function( ldir ){
		CBact.getConstraint("PersistenceConstraint").conf.LAMBDA_DIR[1] = parseFloat(ldir);
		conf.lambdaDirBacteria = parseFloat(ldir);
	}
	setBactRelSpeed = function( value ){
		conf.bactRelSpeed = value
	}
	setLambdaActPhagocytes = function (lact ){
		CAct.getConstraint("ActivityConstraint").conf.LAMBDA_ACT[1] = parseFloat( lact )
		conf.lambdaActPhagocyte = parseFloat(lact);
	}
	setMaxActPhagocytes = function (mact ){
		CAct.getConstraint("ActivityConstraint").conf.MAX_ACT[1] = parseFloat( mact )
		conf.maxActPhagocyte = parseFloat(mact);
	}
	setPhagocytosisRate = function (k ){
		conf.phagocytosisRate = parseInt(k)/1000
		phagocytosisEffectiveRate = conf.phagocytosisRate/conf.bactRelSpeed
	}
	setAttachRate = function(k){
		conf.attachRate = parseInt(k)/1000
		attachEffectiveRate = conf.attachRate/conf.bactRelSpeed
	}
	setDetachRate = function(k){
		conf.detachRate = parseInt(k)/1000
		detachEffectiveRate = conf.detachRate/conf.bactRelSpeed
	}
	setInfectionRate = function(k){
		conf.infectionRate = parseInt(k)/1000
		infectionEffectiveRate = conf.infectionRate/conf.bactRelSpeed
	}
	setSeed = function(s){
		conf.seed = parseInt(s)
	}
	
	toggleRunning = function(){
		running = !running
	}
	
	function setSliders(){
		document.getElementById("ldirbact").value = CBact.getConstraint("PersistenceConstraint").conf.LAMBDA_DIR[1]
		document.getElementById("relvbact").value = conf.bactRelSpeed
		document.getElementById("lactph").value = CAct.getConstraint("ActivityConstraint").conf.LAMBDA_ACT[1]
		document.getElementById("mactph").value = CAct.getConstraint("ActivityConstraint").conf.MAX_ACT[1]
		document.getElementById("kphi").value = conf.phagocytosisRate*1000
		document.getElementById("katt").value = conf.attachRate*1000
		document.getElementById("kdet").value = conf.detachRate*1000
		document.getElementById("kinf").value = conf.infectionRate*1000
		
		document.getElementById("ngob").value = conf.nGoblet
		document.getElementById("nph").value = conf.nPh
		document.getElementById("nbac").value = conf.nBac
		
		document.getElementById("attCol").value = viz.attachedColor
		document.getElementById("invCol").value = viz.invadedColor
	}
	
	function emptyConf(){
		document.getElementById("confSettings").innerHTML = ""
	}
	function emptyViz(){
		document.getElementById("vizSettings").innerHTML = ""
	}
	function getConf(){
		const str = JSON.stringify(conf, undefined, 4)
		document.getElementById("confSettings").innerHTML = str
	}
	function getViz(){
		const str = JSON.stringify(viz, undefined, 4)
		document.getElementById("vizSettings").innerHTML = str
	}
	function cleanOutputs(){
		document.getElementById( "tracksOut" ).innerHTML = "cellID" + "\t" + "timeStep" + "\t" + "x \t y" + "\n"
		document.getElementById( "eventsOut" ).innerHTML = "eventType" + "\t" + "timeStep"+ "\t" + "bactID" + "\t" + "partnerID" + "\n"
	}

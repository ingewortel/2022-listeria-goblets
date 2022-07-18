function initialize(){

	initVariables()	

	// Epidermal layer CPM and Canvas
	CEpi = new CPM.CPM( fieldSize, confEpi )
		
	// Phagocyte layer CPM, Grid manipulator, and Canvas
	CAct = new CPM.CPM( fieldSize, confAct )
	
	// Bacterial layer CPM, adding constraints, Grid manipulator, and Canvas
	CBact = new CPM.CPM( fieldSize, confBact )
	CBact.add( new CPM.HardVolumeRangeConstraint( confBact ) )
	CBact.add( new CPM.PersistenceConstraint( confBact ) ) 
	CBact.add( new CPM.LocalConnectivityConstraint( confBact ) )
	confBact.CPM_GOBLET = CEpi
	CBact.add( new InvadedConstraint( confBact, goblets ) )
	
	
	// Layer for bacteria that have invaded a goblet
	CInf = new CPM.CPM( fieldSize, confInf)
	CInf.add( new CPM.HardVolumeRangeConstraint( confInf ) )
	CInf.add( new CPM.LocalConnectivityConstraint( confInf ) )
	confInf.CPM_GOBLET = CEpi
	CInf.add( new InvadedConstraint( confInf, goblets ) )
	
	
	// Add retraction constraint to the epi grid
	confEpi.CPM_BACT = CBact
	confEpi.CPM_INV = CInf
	CEpi.add( new RetractionConstraint( confEpi, goblets ) )
	
	initHelpers()
	
	// seed cells on the grid
	setup() // contains a burnin period.
	cleanOutputs()
	
}
function initVariables(){
	goblets = {}
	bacteriaCentroids = {}
	
	cometMemory = 20 //conf.bactRelSpeed / 10
	phagocytosisEvents = 0
	infectionEvents = 0
	infectedGoblets = 0
	attachedNum = 0
	
	phagocytosisEffectiveRate = conf.phagocytosisRate/conf.bactRelSpeed
	infectionEffectiveRate = conf.infectionRate/conf.bactRelSpeed
	attachEffectiveRate = conf.attachRate/conf.bactRelSpeed
 	detachEffectiveRate = conf.detachRate/conf.bactRelSpeed
}
function initHelpers(){

	document.getElementById("EpiSim").innerHTML = ""
	document.getElementById("BacSim").innerHTML = ""
	document.getElementById("ActSim").innerHTML = ""
	document.getElementById("InfSim").innerHTML = ""

	CimEpi = new CPM.Canvas( CEpi, {zoom:viz.zoom, parentElement: document.getElementById("EpiSim")} )
	GMEpi = new CPM.GridManipulator( CEpi )
	GMAct = new CPM.GridManipulator( CAct )
	CimAct = new CPM.Canvas( CAct, {zoom:viz.zoom, parentElement: document.getElementById("ActSim")} )
	GMBact = new CPM.GridManipulator( CBact )	
	CimBact = new CPM.Canvas( CBact, {zoom:viz.zoom, parentElement: document.getElementById("BacSim")} )
	GMInf = new CPM.GridManipulator( CInf )	
	CimInf =  new CPM.Canvas( CInf, {zoom:viz.zoom, parentElement: document.getElementById("InfSim")} )
	
}
function setup(){

	// Seed epidermal cell layer, make array of cids to sample from
	let step = Math.floor( 250/17 )+1, cids = []
	for( let i = 0 ; i < CEpi.extents[0] ; i += step ){
		for( let j = 0 ; j < CEpi.extents[1] ; j += step ){
			let x = i, y = j
			if( ( i/step ) % 2 == 0 ) y+= 6
			if( y >= CEpi.extents[1] ) y -= CEpi.extents[1]
		
			const cid = CEpi.makeNewCellID(1)
			const circ = GMEpi.makeCircle( [x,y], 6 )
			cids.push(cid)
			GMEpi.assignCellPixels( circ, 1, cid )
		}
	}
	
	// sample nGoblet cells as goblets; if bacteria initialized in circle, keep that
	// circle empty of goblets.
	let tries = 100
	while( Object.keys(goblets).length < conf.nGoblet && tries >= 0 ){
		const newID = cids[ Math.floor( CEpi.random()*cids.length ) ]
		if( document.getElementById("initCirc").checked ){
			const epicentroids = CEpi.getStat( CPM.CentroidsWithTorusCorrection )
			const dx = epicentroids[newID][0] - CEpi.grid.midpoint[0]
			const dy = epicentroids[newID][1] - CEpi.grid.midpoint[1]
			if( ( dx*dx + dy*dy ) < 30*30 ) continue
		}
		if( !goblets.hasOwnProperty(newID) ) goblets[newID] = 0
		tries--
	}
	
	
	// Randomly seed phagocytes
	for( let ph = 0; ph < conf.nPh; ph++ ){
		GMAct.seedCell(1)
	}
	
	burnin()
	
	if( document.getElementById("initCirc").checked ){
		// seed bacteria in circle in the middle
		GMBact.seedCellsInCircle(1,conf.nBac,CBact.grid.midpoint,radius=20)
	} else {
		// Randomly seed bacteria
		for( let b = 0; b < conf.nBac; b++ ){
			GMBact.seedCell(1)
		}
	}	

}
function burnin(){
	for( let t = 0; t < 20; t++ ) computeStep()
	CEpi.time = 0
	CAct.time = 0
	CBact.time = 0
}
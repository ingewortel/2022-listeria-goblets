
// fit: lambdaDirBacteria, deltat, persist
// the objective function will choose the bactRelSpeed.
let seed = parseInt( process.argv[2] )
let ldir = parseFloat( process.argv[3] )
let deltat = parseInt( process.argv[4] )
let persist = parseFloat( process.argv[5] )/1000
let MCSperSecond = parseInt( process.argv[6] )

// Note: this is the path from where this script is located, *not* from where it is called!
let CPM = require("../artistoo/artistoo-cjs.js")

let confBact = {
	torus : [true,true],				// Should the grid have linked borders?
	seed : seed,							// Seed for random number generation.
	T : 20,								// CPM temperature
		
	LAMBDA_VRANGE_MIN : [0,1],			// MIN/MAX volume for the hard volume constraint
	LAMBDA_VRANGE_MAX : [0,2],
	
	LAMBDA_DIR : [0,ldir], 
	//CHANGERATE : [0,0.001],
	PERSIST : [0,persist],
	DELTA_T : [0,deltat]
}


let config = {
	field_size : [697,523],	// boundingbox of original data: 348.5 um x 261.4 um. 2 pixels/micron, so twice that.
	conf : confBact,
	simsettings : {
		NRCELLS : [50],
		RUNTIME : MCSperSecond * 30, // 30 seconds
		LOGRATE : 10,
		SAVEIMG: false
	}
}

let sim = new CPM.Simulation( config )
sim.C.add( new CPM.HardVolumeRangeConstraint( confBact ) )
sim.C.add( new CPM.PersistenceConstraint( confBact ) )

sim.run()

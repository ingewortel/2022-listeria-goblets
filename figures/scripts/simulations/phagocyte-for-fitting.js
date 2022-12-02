// This is the same model as is included in the full model, but for simplicity we now
// simulate only the phagocyte layer.


// Relative path from this script to the artistoo source code.
let CPM = require("../artistoo/artistoo-cjs.js")

// input arguments
let seed = parseInt( process.argv[2] )
let lact = parseFloat( process.argv[3] )
let mact = parseFloat( process.argv[4] )
let relSpeed = parseInt( process.argv[5] ) // MCS per second


let conf = {
	nPh : 40,
	runtime : 1000
}

let confAct = {
	torus : [true,true],				// Should the grid have linked borders?
	seed : conf.seed,							// Seed for random number generation.
	T : 20,								// CPM temperature
	J : [ [NaN,20],	[20,100] ],
	LAMBDA_V : [0,50],					// VolumeConstraint importance per cellkind
	V : [0,314],						// Target volume of each cellkind
	LAMBDA_P : [0,1.5],					// PerimeterConstraint importance per cellkind
	P : [0,230], 						// Target perimeter of each cellkind
	LAMBDA_ACT : [0,lact],
	MAX_ACT : [0,mact],
	ACT_MEAN : "geometric"

}


let config = {
	field_size : [400, 300], // 150 x 200 micron is 300 x 400 pixels
	conf : confAct,
	simsettings : {
		NRCELLS : [conf.nPh],
		RUNTIME : relSpeed*conf.runtime, // 1 hour
		LOGRATE : 5,
		SAVEIMG: false
	}
}

let sim = new CPM.Simulation( config )


sim.run()
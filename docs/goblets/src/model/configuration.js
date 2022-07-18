/*	----------------------------------
	CONFIGURATION SETTINGS
	----------------------------------
*/

let conf = {
	seed : 1,
	nGoblet : 20,
	nBac : 40,
	nPh : 0,
	infectionRate : (1/600),
	phagocytosisRate : 0.336,
	attachRate : 0.0071,
	detachRate : 0,
	bactRelSpeed : 150,
	runtime : 3600,
	lambdaActPhagocyte : 400,
	maxActPhagocyte : 20,
	lambdaDirBacteria : 40
}

let viz = {
	gobletColor : "CCCCCC", //"0000CC",
	epitheliumColor : "EEEEEE",
	epitheliumBorder : "AAAAAA",
	phagocyteColor : "cd2990", //"DD00DD",
	actGradientMin : "cd2990",
	actGradientMax : "000000",
	bacteriaColor : "1c86ee", //"1874CD",
	cometColor : "1c86ee", //"1874CD", // was "FF0000"
	attachedColor : "888888", //"FFCC00",
	invadedColor : "000000",
	invadedGoblets : "999999",//"E67F00",
	zoom : 2
}

// Don't touch below here.

const fieldSize = [250,250]

// first population is the 'free' motile bacteria; second contains 'attached but not yet invaded' ones.
let confBact = {
	torus : [true,true],				// Should the grid have linked borders?
	seed : conf.seed,							// Seed for random number generation.
	T : 20,								// CPM temperature
		
	LAMBDA_VRANGE_MIN : [0,1,1],			// MIN/MAX volume for the hard volume constraint
	LAMBDA_VRANGE_MAX : [0,2,2],
	
	LAMBDA_DIR : [0,conf.lambdaDirBacteria,0], 
	//CHANGERATE : [0,0.001],
	PERSIST : [0,0,0],
	DELTA_T : [0,60,0],
	CONNECTED : [false,true,true],
	STICK : [false,false,true], // the 'attached' bacteria stick to their goblet
	CPM_GOBLET : undefined // assigned below
}

let confInf = {
	torus : [true,true],				// Should the grid have linked borders?
	seed : conf.seed,							// Seed for random number generation.
	T : 20,								// CPM temperature
		
	LAMBDA_VRANGE_MIN : [0,1],			// MIN/MAX volume for the hard volume constraint
	LAMBDA_VRANGE_MAX : [0,2],
	CONNECTED : [false,true],
	STICK : [false,true],
	CPM_GOBLET : undefined // assigned below
}

let confEpi = {
	torus : [true,true],				// Should the grid have linked borders?
	CPM_BACT : undefined, // assigned below
	CPM_INV: undefined, //assigned below
	seed : conf.seed,							// Seed for random number generation.
	T : 20,								// CPM temperature
	J : [ [NaN,20],	[20,30] ],
	LAMBDA_V : [0,50],					// VolumeConstraint importance per cellkind
	V : [0,222]						// Target volume of each cellkind
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
	LAMBDA_ACT : [0,conf.lambdaActPhagocyte],
	MAX_ACT : [0,conf.maxActPhagocyte],
	ACT_MEAN : "geometric"

}


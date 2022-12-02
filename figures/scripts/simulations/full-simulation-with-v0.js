/* Get command line arguments; default values are between square brackets:
 *	-d [draw="none"] (opt):	if specified, images are saved under 
 *								data/img/[value]/[value]-t[time].png.
 *  -t [track=false] (opt): if given, tracks are also outputted for all bacteria & phagocytes.
 *	-n [simulation no = 1]:	used as the seed of the random number generator used
 *	-p [nPh = 0] :			number of phagocytes
 *  -b [nBac = 40] :		number of bacteria
 *  -g [nGob = 20] :		number of goblets
 *  -f [k_phi=0]:				1000 x phagocytosis rate (in sec^-1) (e.g. for rate 0.5sec^-1,
 *								this argument should be 500.)
 *  -i [k_infect=0] :		1000 x infection rate (in sec^-1)
 *  -a [k_attach=0] : 		1000 x attachment rate (in sec^-1)
 *  -r [k_detach=0] :		1000 x detachment `return to motility` rate (in sec^-1)
 *  -v [bact relspeed=150]:	number of steps of the bacterial model per second; this is a
 *								proxy of bacterial speed. For v = 0, we run no motility 
 *								steps, by enforcing vrange_max = 1 such that bacteria cannot move.
 *  -x [ldir bact=40]:		lambda_dir for directionality in bacteria motion.
 *  -l [lact=400]:			lambda_act for phagocyte motion
 *  -m [mact=20]:			max_act for phagocyte motion
 *  -V [verbose = false]:	for debugging; show conf object in the console.
 *  -T [runtime = 3600]:	simulation max run time in seconds.
 */

const args = require('minimist')(process.argv.slice(2));


function getInput( name, defaultValue, type = undefined ){
	
	if( !args.hasOwnProperty(name)) return defaultValue
	if( type === "boolean" ){ return true }
	else if( type === "int" ){ return parseInt( args[name] ) } 
	else if (type === "float" ){ return parseFloat( args[name] ) } 
	else { return args[name] }
}


const seed = getInput( "n", 1, "int" ) //parseInt( args.n ) || 1
const nBac = getInput( "b", 40, "int" ) //parseInt( args.b ) || 40
const nPh = getInput( "p", 0, "int" ) //parseInt( args.p ) || 0 
const nGob = getInput( "g", 20, "int" )
const infectionRate = getInput( "i", 200, "float" ) // parseFloat( args.i )|| (1000/600)
const phagocytosisRate = getInput( "f", 51, "float" ) //parseFloat( args.f ) || 0 // was 336
const attachRate = getInput( "a", 51, "float" ) //parseFloat( args.a )  || 7.1
const detachRate = getInput( "r", 0, "float" ) //parseFloat( args.r ) || 0 
let bactRelSpeed = getInput( "v", 150, "int" ) //parseInt( args.v ) || 150
const lambdaActPhagocyte = getInput( "l", 400, "int" ) //parseInt( args.l ) || 400
const maxActPhagocyte = getInput( "m", 20, "int" ) //parseInt( args.m) || 20
const lambdaDirBacteria = getInput( "x", 40, "int" ) //parseInt( args.x ) || 40
const runtime = getInput( "T", 3600, "int" )
const verbose = getInput( "V", false, "boolean" )

// We need bactRelSpeed at least 1 for the algorithm/outputs to still work.
// But if we want bacteria speed to be zero, set vrange_max = 1 to accomplish the
// same, then set bactRelSpeed back to 1 so the algorithm works.
let vRangeMax = 2 
if( bactRelSpeed == 0 ){
	vRangeMax = 1
	bactRelSpeed = 1
} 

let conf = {
	nGoblet : nGob,
	runtime : runtime, // 1 hour
		
	seed : seed,
	nBac : nBac,
	nPh : nPh, 
	infectionRate : infectionRate/1000,//0.005,
	phagocytosisRate : phagocytosisRate/1000,
	attachRate : attachRate/1000,
	detachRate : detachRate/1000,
	bactRelSpeed : bactRelSpeed,
	lambdaActPhagocyte : lambdaActPhagocyte,
	maxActPhagocyte : maxActPhagocyte,
	lambdaDirBacteria : lambdaDirBacteria
}

if( verbose ) console.log(conf)


const imgsave = args.d || "none"
const tracksout = args.t || false

if( verbose) console.log( imgsave )

const outpath = "data/img/" + imgsave + "/" + imgsave + "-t"



let CPM = require("../artistoo/artistoo-cjs.js")
const constraints = require("./constraints.js")

/* ============================ Configuration ============================ */



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
	LAMBDA_VRANGE_MAX : [0,vRangeMax,vRangeMax],
	
	LAMBDA_DIR : [0,conf.lambdaDirBacteria,0], // only the 'motile' bacteria move, the 'attached' ones don't.
	PERSIST : [0,0,0],
	DELTA_T : [0,60,0],
	CONNECTED : [false,true,true],
	STICK : [false,false,true], 		// the 'attached' bacteria stick to their goblet
	CPM_GOBLET : undefined // assigned below
}


let confInf = {
	torus : [true,true],				// Should the grid have linked borders?
	seed : conf.seed,							// Seed for random number generation.
	T : 20,								// CPM temperature
		
	LAMBDA_VRANGE_MIN : [0,1],			// MIN/MAX volume for the hard volume constraint
	LAMBDA_VRANGE_MAX : [0,vRangeMax],
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



/* ============================ Model ============================ */


/*	---------------------------------- */
let CBact, CEpi, CAct, CInf,
	GMBact, GMEpi, GMAct, GMInf,
	CimEpi, CimBact, CimAct, CimInf

// variables
let phagocytosisEffectiveRate, infectionEffectiveRate, attachEffectiveRate, detachEffectiveRate,
	bacteriaCentroids, cometMemory,
	phagocytosisEvents, infectionEvents, attachedNum, infectedGoblets, goblets,
	minColor, maxColor

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
	CBact.add( new constraints.InvadedConstraint( confBact, goblets ) )
	
	
	// Layer for bacteria that have invaded a goblet
	CInf = new CPM.CPM( fieldSize, confInf)
	CInf.add( new CPM.HardVolumeRangeConstraint( confInf ) )
	CInf.add( new CPM.LocalConnectivityConstraint( confInf ) )
	confInf.CPM_GOBLET = CEpi
	CInf.add( new constraints.InvadedConstraint( confInf, goblets ) )
	
	// Add retraction constraint to the epi grid
	confEpi.CPM_BACT = CBact
	confEpi.CPM_INV = CInf
	CEpi.add( new constraints.RetractionConstraint( confEpi, goblets ) )
	
	
	initHelpers()
	
	// seed cells on the grid
	setup() // contains a burnin period.

}
function initVariables(){
	goblets = {}
	bacteriaCentroids = {}
	
	cometMemory = 20 //conf.bactRelSpeed / 10
	phagocytosisEvents = 0
	infectionEvents = 0
	infectedGoblets = 0, 
	attachedNum = 0
	
	
	phagocytosisEffectiveRate = conf.phagocytosisRate/conf.bactRelSpeed
	infectionEffectiveRate = conf.infectionRate/conf.bactRelSpeed
	attachEffectiveRate = conf.attachRate/conf.bactRelSpeed
	detachEffectiveRate = conf.detachRate/conf.bactRelSpeed
}
function initHelpers(){

	CimEpi = new CPM.Canvas( CEpi, {zoom:viz.zoom} )
	GMEpi = new CPM.GridManipulator( CEpi )
	GMAct = new CPM.GridManipulator( CAct )
	CimAct = new CPM.Canvas( CAct, {zoom:viz.zoom} )
	GMBact = new CPM.GridManipulator( CBact )	
	CimBact = new CPM.Canvas( CBact, {zoom:viz.zoom} )
	GMInf = new CPM.GridManipulator( CInf )	
	CimInf =  new CPM.Canvas( CInf, {zoom:viz.zoom} )
	
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
	
	// sample nGoblet cells as goblets
	let tries = 10000
	while( Object.keys(goblets).length < conf.nGoblet && tries >= 0 ){
		const newID = cids[ Math.floor( CEpi.random()*cids.length ) ]
		if( !goblets.hasOwnProperty(newID) ) goblets[newID] = 0
		tries--
	}
	
	// Randomly seed phagocytes
	for( let ph = 0; ph < conf.nPh; ph++ ){
		GMAct.seedCell(1)
	}
	
	// Randomly seed bacteria
	for( let b = 0; b < conf.nBac; b++ ){
		GMBact.seedCell(1)
	}

}
function burnin(){
	for( let t = 0; t < 20; t++ ) computeStep( false )
	CEpi.time = 0
	CAct.time = 0
	CBact.time = 0
	CInf.time = 0
}

// Bacteria dynamics
function updateInfected(){

	// clear cache
	CBact.stats = {}
	const allpix = CBact.getStat( CPM.PixelsByCell )
	
	// loop over all bacteria (motile or attached)
	for( let bact of CBact.cellIDs() ){
		const bpix = allpix[bact]
		const bactKind = CBact.cellKind( bact )
		// check for every pixel of this bact if it's on top of a goblet. invasion
		// or attachment only once *all* pixels of the bacterium are on top of the goblet.
		const epiID = CEpi.pixt(bpix[0])
		if( goblets.hasOwnProperty(epiID) ){
			const fullContact = bpix.every( function(p){ return ( CEpi.pixt(p) == epiID ) } )
			if( fullContact){
				 			
 				// if the bacterium is motile: attach attempt for its first pixel
 				if( bactKind == 1 ){
 					attachAttempt( bact, epiID, bpix[0] )
 				}
 				// otherwise it's already attached, and can either stay, detach or invade.
 				// all these options are handled by 'infectionAttempt'.
 				else if ( bactKind == 2 ) {
 					infectionAttempt( bact, epiID, bpix[0] )
 				}	
			
			}
		}	
	}
}
function updatePhagocytosed(){
	const allpix = CBact.getStat( CPM.PixelsByCell )
	for( let bact of CBact.cellIDs() ){
		const bpix = allpix[bact]
		for( let p of bpix ){
			if( CAct.pixt(p) > 0 ){
				phagocytosisAttempt( bact, CAct.pixt(p) )
				continue
			}
		}
	}
}

function attachAttempt( bact, gobletID, p ){
	if( CBact.random() < attachEffectiveRate ){
		if( true ){
			const outString = ["attachment",CEpi.time, bact, gobletID].join("\t") + "\n"
			console.log(outString)
		}
		
		// switch bacterium from motile to attached population
		attachedNum++
		CBact.setCellKind(bact,2)
	}
}

function infectionAttempt( bact, gobletID, p ){

	const randNum = CBact.random()
	// bacterium can invade:
	if( randNum < infectionEffectiveRate ){
		// increase counter the first time a goblet gets infected
		if( goblets[gobletID] == 0 ) infectedGoblets++
		// add bacteria to the count inside the goblet, bump infection events
		goblets[gobletID]++
		infectionEvents++
		attachedNum--
		if( true ){
			const outString = ["infection",CEpi.time, bact, gobletID].join("\t") + "\n"
			console.log(outString)
		}
		
		// remove bacterium from the migration grid.
		GMBact.killCell(bact)
		seedInGoblet( gobletID, p )
	}
	// or bacterium can detach:
	else if( randNum < infectionEffectiveRate + detachEffectiveRate ){
		attachedNum--
		console.log( ["detachment",CEpi.time, bact, gobletID].join("\t") + "\n" )
		
		// switch back to motile population
		CBact.setCellKind(bact, 1)
	}
}
function phagocytosisAttempt(bact, phagID){
	if( CBact.random() < phagocytosisEffectiveRate ){

		if( CBact.cellKind( bact )  == 2 ) attachedNum--
		GMBact.killCell(bact)
		phagocytosisEvents++
		if( true ){
			const outString = ["phagocytosis",CEpi.time, bact, phagID].join("\t") + "\n"
			console.log( outString )	
		}
	}
}
function seedInGoblet( gobletID, p ){

	// try seeding in this exact spot
	if( CInf.pixt(p) == 0 ){
		GMInf.seedCellAt( 1, p )
	} 
	
	else {
		const gobletPixels = CEpi.getStat( CPM.PixelsByCell )[gobletID]
		for( let p of gobletPixels ){
			if( CInf.pixt(p) == 0 ){
				GMInf.seedCellAt( 1, p )
				break
			}
		}
	}
}





/* ============================ Outputs ============================ */


function draw(){

	drawEpidermis()
	drawPhagocytes()
	drawBacteria()	
	
	// scalebar of 20px
	const ctx = CimBact.ctx, zoom = CimBact.zoom
	ctx.strokeStyle = "#000000"
	ctx.beginPath()
	ctx.lineWidth = 2
	
	ctx.moveTo( 10*zoom ,(CBact.extents[1]-10)*zoom )
	ctx.lineTo( 30*zoom ,(CBact.extents[1]-10)*zoom )
	ctx.stroke()
	
	// time logger: top left
	const currentTime = new Date( CEpi.time*1000).toISOString().substr(11,8)
	ctx.font = "12px Arial"
	ctx.textBaseline = 'middle'
	ctx.fillStyle = "#000000"
	ctx.fillText(currentTime, 35*zoom, (CBact.extents[1]-10)*zoom )
	
	// log attached, invaded, phagocytosed.
	const logString = "A: " + attachedNum + ", I: " + infectionEvents + ", P: " + phagocytosisEvents
	ctx.fillText(logString, 80*zoom, (CBact.extents[1]-10)*zoom )
	
	// add everything on top of CimEpi and draw that one to png.
	CimEpi.ctx.drawImage( CimInf.ctx.canvas, 0, 0 )
	CimEpi.ctx.drawImage( CimAct.ctx.canvas, 0, 0 )
	CimEpi.ctx.drawImage( CimBact.ctx.canvas, 0, 0 )
	CimEpi.writePNG( outpath +CEpi.time+".png" )
	
}
function drawEpidermis(){
	// gray background, draw goblets in blue, overlay with cell borders in darker gray.
	CimEpi.clear( viz.epitheliumColor )
	drawGoblets()
	CimEpi.drawCellBorders( 1, viz.epitheliumBorder )
}
function drawGoblets(){
	let cellpixelsbyid = CEpi.getStat(CPM.PixelsByCell)
	CimEpi.getImageData()
	for (let cid of Object.keys(goblets)) {
		CimEpi.col( viz.gobletColor )		
		for (let cp of cellpixelsbyid[cid]) CimEpi.pxfi(cp)
	}
	CimEpi.putImageData()
}
function drawPhagocytes(){
	
	CimAct.ctx.clearRect(0,0, CAct.extents[0]*CimAct.zoom, CAct.extents[1]*CimAct.zoom)
	
	CimAct.drawCells(1,viz.phagocyteColor)
	CimAct.col( viz.actGradientMin )
	minColor = [ CimAct.col_r, CimAct.col_g, CimAct.col_b ]
	CimAct.col( viz.actGradientMax )
	maxColor = [ CimAct.col_r, CimAct.col_g, CimAct.col_b ]
	CimAct.drawActivityValues( 1, CAct.getConstraint("ActivityConstraint"), actcolfun )
	

}
function actcolfun(a ){
	let begin = minColor //[221,0,221] //pink
	let end = maxColor //[0,0,0] //black
	let diff = [0,0,0]
	for( let i = 0; i < begin.length; i++ ){ diff[i] = end[i] - begin[i] }

	let r = [0,0,0]
	for( let i = 0; i < r.length; i++ ){
		r[i] = begin[i] + a * diff[i]
	}
	return r
}
function drawBacteria(){

	CimBact.ctx.clearRect(0,0, CBact.extents[0]*CimBact.zoom, CBact.extents[1]*CimBact.zoom)
	
	// overlay lower layers with transparent white to fade out
	CimBact.ctx.globalAlpha = 0.5;
	CimBact.clear("FFFFFF")
	CimBact.ctx.globalAlpha = 1.0;

	drawComets()
	CimBact.drawCells(1, viz.bacteriaColor )
	CimBact.drawCells(2, viz.attachedColor )
	drawInvaded()
}
function updateComets(){
	const centroids = CBact.getStat( CPM.CentroidsWithTorusCorrection )
	for( let bact of CBact.cellIDs() ){
		if( !bacteriaCentroids.hasOwnProperty(bact) ){
			bacteriaCentroids[bact] = []
		}
		bacteriaCentroids[bact].push( centroids[bact] )
		if( bacteriaCentroids[bact].length > cometMemory ){
			bacteriaCentroids[bact].shift()
		}
	}
}
function drawComets(){
	const ctx = CimBact.ctx
	ctx.globalAlpha = 0.2;
	ctx.strokeStyle="#" + viz.cometColor
	ctx.beginPath()
	ctx.lineWidth = 2

	for( let b of CBact.cellIDs() ){
		
		const trace = bacteriaCentroids[b]
		if( trace.length >= 2 ){
			let start = [trace[0][0]*CimBact.zoom,trace[0][1]*CimBact.zoom]
			ctx.moveTo( start[0],start[1] )
			for( let t = 1; t < trace.length; t++ ){
				let end = [trace[t][0]*CimBact.zoom,trace[t][1]*CimBact.zoom]
				if( ( Math.abs( start[0]-end[0] ) < 10 ) && ( Math.abs( start[1]-end[1] ) < 10 ) ){
					ctx.lineTo( end[0],end[1])
					ctx.moveTo( end[0],end[1])
					start = end.slice()
				} else {
					ctx.moveTo( end[0],end[1])
					start = end.slice()
				}
				//ctx.lineTo(  )
			}
		}
	}
	ctx.stroke()
	ctx.globalAlpha = 1;	
}
function drawInvaded(){
	CimInf.ctx.clearRect(0,0, CInf.extents[0]*CimInf.zoom, CInf.extents[1]*CimInf.zoom)
	CimInf.drawCells( 1, viz.invadedColor )
}






function logOutputs(){
	
	// log tracks every 10 MCS
	if( CEpi.time % 1 == 0 && tracksout ){
	
		const centroidsPhagocytes = CAct.getStat( CPM.CentroidsWithTorusCorrection )
		const centroidsBacteria = CBact.getStat( CPM.CentroidsWithTorusCorrection )
		let outString = ""
		for( let cid of CAct.cellIDs() ){
			outString += "ph" + cid + "\t" + CEpi.time + "\t" + centroidsPhagocytes[cid].join("\t") + "\n"
		}
		for( let cid of CBact.cellIDs() ){
			outString += "bac" + cid + "\t" + CEpi.time + "\t" + centroidsBacteria[cid].join("\t") + "\n"
		}
		console.log( outString )	
		
	}
	
	
}





/* ============================ Run ============================ */

function computeStep( outputs = true ){
	CEpi.timeStep()
	CAct.timeStep()
	for( let t=0; t < conf.bactRelSpeed; t++ ){ 
		CBact.timeStep()
		// the following only after burnin phase
		if( outputs ){
			if ( t % 10 == 0 ) updateComets()
			updatePhagocytosed()
			updateInfected()
		}

	}
	CInf.timeStep()
	if( outputs ){
		logOutputs()
		if( imgsave != "none" ) draw()
	}
}

function run(){
	initialize()
	burnin()
	let running = true
	while( running && CEpi.time <= conf.runtime ){
		computeStep()
		
		// stop the simulation if there are no free bacteria anymore
		count = 0
		for( let b of CBact.cellIDs() ){
			count++
		}
		if( count == 0 ){
			running = false
			console.log( "SIMULATION END: No free bacteria left.")
			return
		}
	}
	console.log( "SIMULATION END: Time out; " + count + " bacteria left.")
	
}
let count
run()



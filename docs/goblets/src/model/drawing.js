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
	
}
function drawEpidermis(){
	// gray background, draw goblets in blue, overlay with cell borders in darker gray.
	CimEpi.clear( viz.epitheliumColor )
	if( document.getElementById("showEpidermis").checked ){
		drawGoblets()
		CimEpi.drawCellBorders( 1, viz.epitheliumBorder )
	}
	if( document.getElementById("initCirc").checked ){
		const ctx = CimEpi.ctx, zoom = CimEpi.zoom
		ctx.strokeStyle = "#1c86ee"
		ctx.lineWidth = .75
		ctx.beginPath()
		ctx.arc( CEpi.grid.midpoint[0]*zoom, CEpi.grid.midpoint[1]*zoom, 20*zoom, 0, 2*Math.PI )
		ctx.stroke()
	}
}
function drawGoblets(){
	let cellpixelsbyid = CEpi.getStat(CPM.PixelsByCell)
	
	
	CimEpi.getImageData()
	for (let cid of Object.keys(goblets)) {
		if( goblets[cid] > 0 ){
			CimEpi.col( viz.invadedGoblets )		
			for (let cp of cellpixelsbyid[cid]) CimEpi.pxfi(cp)
		} else {
			CimEpi.col( viz.gobletColor )		
			for (let cp of cellpixelsbyid[cid]) CimEpi.pxfi(cp)		
		}

	}
	CimEpi.putImageData()
}
function drawPhagocytes(){
	
	CimAct.ctx.clearRect(0,0, CAct.extents[0]*CimAct.zoom, CAct.extents[1]*CimAct.zoom)
	if( document.getElementById("showPhagocytes").checked ){
		CimAct.drawCells(1,viz.phagocyteColor)
		CimAct.col( viz.actGradientMin )
		minColor = [ CimAct.col_r, CimAct.col_g, CimAct.col_b ]
		CimAct.col( viz.actGradientMax )
		maxColor = [ CimAct.col_r, CimAct.col_g, CimAct.col_b ]
		if( document.getElementById("showAct").checked ) CimAct.drawActivityValues( 1, CAct.getConstraint("ActivityConstraint"), actcolfun )
	}

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
	if( document.getElementById("showBacteria").checked ){
		if( document.getElementById("washout").checked ){
			// overlay lower layers with transparent white to fade out
			CimBact.ctx.globalAlpha = 0.6; // was 0.5
			CimBact.clear("FFFFFF")
			CimBact.ctx.globalAlpha = 1.0;
		}
		if( document.getElementById("showTraces").checked ) drawComets()
		CimBact.drawCells(1, viz.bacteriaColor )
		CimBact.drawCells(2, viz.attachedColor )
	}
	if( document.getElementById("showInvaded").checked ){
		drawInvaded()
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
		if( typeof trace !== "undefined" && trace.length >= 2 ){
			let start = [trace[0][0]*CimBact.zoom,trace[0][1]*CimBact.zoom]
			ctx.moveTo( start[0],start[1] )
			for( let t = 1; t < trace.length; t++ ){
				let end = [trace[t][0]*CimBact.zoom,trace[t][1]*CimBact.zoom]
				if( ( Math.abs( start[0]-end[0] ) < 50 ) && ( Math.abs( start[1]-end[1] ) < 50 ) ){
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
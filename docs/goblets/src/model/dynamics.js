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
				// log the contact if it's a free bacterium
				//if( bactKind == 1 ) console.log( ["contact",CEpi.time, bact, epiID].join("\t") + "\n" )
 			
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
 		if( false ){
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
		if( document.getElementById("recEvents").checked ){
			const outString = ["infection",CEpi.time, bact, gobletID].join("\t") + "\n"
			document.getElementById("eventsOut").innerHTML += outString	
		}
		
		// remove bacterium from the migration grid.
		GMBact.killCell(bact)
		seedInGoblet( gobletID, p )
	}
	// or bacterium can detach:
 	else if( randNum < infectionEffectiveRate + detachEffectiveRate ){
 		attachedNum--
 		//console.log( ["detachment",CEpi.time, bact, gobletID].join("\t") + "\n" )
 		
 		// switch back to motile population
 		CBact.setCellKind(bact, 1)
 	}
}
function phagocytosisAttempt(bact, phagID){
	if( CBact.random() < phagocytosisEffectiveRate ){
		const bk = CBact.cellKind( bact )
		if( bk == 2 ) attachedNum--
		GMBact.killCell(bact)
		phagocytosisEvents++
		if( document.getElementById("recEvents").checked ){
			const outString = ["phagocytosis",CEpi.time, bact, phagID].join("\t") + "\n"
			document.getElementById("eventsOut").innerHTML += outString	
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
				//console.log( "seeded 2" )
				break
			}
		}
	}
}
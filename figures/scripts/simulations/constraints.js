const CPM = require("../artistoo/artistoo-cjs.js")


/* Constraint for the epidermal layer: forbid retraction of the cell on a pixel that
contains a bacterium. */
class RetractionConstraint extends CPM.HardConstraint {
	constructor( conf, goblets ){
		super(conf)
		this.bacteriaC = conf.CPM_BACT
		this.invadedC = conf.CPM_INV
		this.bactIC = this.bacteriaC.getConstraint( "InvadedConstraint" )
		this.infIC = this.invadedC.getConstraint( "InvadedConstraint" )
		this.goblets = goblets
	}
	fulfilled( src_i, tgt_i, src_type, tgt_type ){
		//return false
		// if the target pixel to be changed is a goblet pixel that another cell or background
		// copies into (we already know src_type != tgt_type because of the algorithm)
		if( this.goblets.hasOwnProperty( tgt_type ) ){
			// check if this position contains a sticky bacterium in the bacterial/invaded 
			// CPM; if this is the case, forbid the cell from retracting at this pos.
			const bid = this.bacteriaC.pixti(tgt_i)
			const iid = this.invadedC.pixti(tgt_i)
			if( this.bactIC.cellParameter( "STICK", bid ) ) return false
			if( this.infIC.cellParameter( "STICK", iid ) ) return false
		}
		return true
	}
}

/* New class for the invaded particles. Large penalty for positions that are not inside
the assigned cid on the epithelial CPM. 

Note: Bacteria can have either 1 or 2 pixels. That means it is 
possible that 1 is inside the goblet and one is outside when the bacterium "invades" or
"sticks". In that case, the penalty stems from the "outside" pixel, and having or not 
having the second pixel in the goblet does not contribute to deltaH - so the bacterium
can lose that pixel and end up fully outside of the goblet. 
To prevent this: bacteria can only invade/attach if *all* their pixels are on top of the
same goblet. Once they attach, the penalty kicks in and it becomes very unlikely that they
generate a second pixel outside of the goblet. */
class InvadedConstraint extends CPM.HardConstraint {
	constructor( conf, goblets ){
		super(conf)
		this.gobletC = conf.CPM_GOBLET
		this.parentCells = {}
		this.goblets = goblets
	}
	
	set CPM ( C ){
		super.CPM = C
		this.initParents(C)
	}
	
	initParents(C){
		for( let [p,cid] of C.grid.pixels() ){
			
			if( !this.parentCells.hasOwnProperty(cid) && this.inGoblet(p) ){
				this.parentCells[cid] = this.gobletC.pixt(p)
			}
		}
	}
	
	inGoblet(p){
		const epiID = this.gobletC.pixt(p)
		if( this.goblets.hasOwnProperty( epiID ) ) return true
		return false
	}
	
	inGobleti(i){
		const epiID = this.gobletC.pixti(i)
		if( this.goblets.hasOwnProperty( epiID ) ) return true
		return false
	}
	
	postSetpixListener( i, t_old, t_new  ){
		// seeding a non-background cell (a bacterium): parent cell only relevant for 'sticky' cells
		// with positive lambda, and only if this cell is seeded into a goblet.
		const sticky = this.cellParameter( "STICK", t_new )
		if( sticky && this.inGobleti(i) ){
			// if this is a new cell, assign it to the id of the cell at this position in
			// the linked CPM
			// if the first time, add to parentCells and outsideContacts
			if( !this.parentCells.hasOwnProperty(t_new) ){
				this.parentCells[t_new] = this.gobletC.pixti(i)
			} 
		} 	
	}
	
	/*H( i, cid ){
		const lambda = this.cellParameter( "LAMBDA_STICK", cid )
		// do nothing for the background
		if( cid == 0 ) return 0
		
		// penalty for all bacteria pixels outside of the goblet
		if( this.gobletC.pixti(i) != this.parentCells[cid] ) return lambda
		
		return 0
	}
	
	deltaH( sourcei, targeti, src_type, tgt_type ){
		return this.H( targeti, src_type ) - this.H( targeti, tgt_type )
	}*/
	
	fulfilled( sourcei, targeti, src_type, tgt_type ){
		// do nothing for the background
		const sticky = this.cellParameter( "STICK", src_type )
		if( !sticky ) return true
		
		// forbid bacteria pixels copying from goblet to outside of goblet
		if( this.inGobleti( sourcei ) ){
			if( this.gobletC.pixti(targeti) != this.parentCells[src_type] ) return false
		}
		
		
		return true
	}
}


module.exports = {
	InvadedConstraint : InvadedConstraint,
	RetractionConstraint : RetractionConstraint
}
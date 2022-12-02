import sys
import multiprocessing as mp
import numpy as np
import pandas as pd
from Naked.toolshed.shell import execute_js
from os import path

""" 
	=========================== settings ===========================
"""

# Settings from command line
simulationScript = sys.argv[1]
parms = sys.argv[2]
outFolder = sys.argv[3]
nsim = int( sys.argv[4] )
expName = sys.argv[5]
maxProcessors = int( sys.argv[6] )


# Some other initial settings
nProcessors = mp.cpu_count()
if nProcessors > maxProcessors:
	nProcessors = maxProcessors


""" 
	=========================== Functions ===========================
"""


""" Function to run the node script at given parameters.
"""
def run_node(parms) :
	# simulation numbers not zero-indexed, so +1
	id = parms[0]+1
	
	parmString = ""
	for i in range( len( paramNames ) ) :
		pName = paramNames[i]
		pValue = parms[i+1]
		parmString += " -" + pName + " " + str( pValue )
		
	fileString = parmString.replace( " ", "" )
		
	outfile = outFolder + "/" + expName + fileString + "-sim" + str(id) + ".txt"
	argString = parmString + " -n " + str(id) + " > " + outfile	
	
	if path.exists(outfile):
		# do nothing, the file already exists.
		pass
	else:
		success = execute_js( simulationScript, argString )
		if success:
			pass
		else:
			raise NameError("error in node: " + argString )



""" Parallel computation of the simulations at a given parameter combination
"""
def run_all( theParms ):
	
    with mp.Pool( nProcessors ) as pool:
        result = pool.imap( run_node, theParms.itertuples(name=None), chunksize = 2 )
        output = pd.DataFrame()
        sims = 0
        for x in result:
            sims = sims+1
    print( "..." + str(sims) + " simulations done at params: " + theParms.iloc[[0]].to_string( header = False, index = False ) )


"""
    =========================== SCRIPT ===========================
"""

# Read the parameter file
parmTable = pd.read_table( parms, sep = "\t" )

paramNames = []
for col in parmTable.columns:
	paramNames.append(col)

# Loop over the settings in this file line by line, and call the function
# run_node() to take care of running the appropriate number of simulations, etc.
for i in range(0,len(parmTable)):
	theParms = parmTable.loc[[i]]
	theParms = pd.concat( [theParms]*nsim, ignore_index=True )
	if __name__ == '__main__':    
		run_all( theParms )



	


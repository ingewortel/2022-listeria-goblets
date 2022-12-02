library( celltrackR )
argv <- commandArgs( trailingOnly = TRUE )

infile <- argv[1]
outfile <- argv[2]


tr <- read.tracks.csv( infile, 
	pos.column = 1:3, id.column = 8, time.column = 13, 
	skip = 1, sep = "," )
tr <- projectDimensions( tr )
saveRDS( tr, file = outfile )

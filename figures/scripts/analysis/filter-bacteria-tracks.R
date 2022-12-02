library( celltrackR )

source("../scripts/analysis/deltaBIC.R")

argv <- commandArgs( trailingOnly = TRUE )

infile <- argv[1]
outfile <- argv[2]


tr <- readRDS( infile )


# To filter out non-motile cells, set a threshold for this deltaBIC value
deltaBIC <- sapply( tr, deltaBIC, sigma = 1 )
motile <- tr[ deltaBIC >= 50 ]

saveRDS( motile, file = outfile )
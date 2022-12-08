These files contain tracks for neutrophils tracked in mice in vivo.

## Experiment

To quantify the statistics of neutrophil migration on the epithelium for 
model parametrisation, LysM-GFP reporter mice were anesthetized, and 
an incision made in the lower abdomen to expose the ileum for intraluminal 
infection, which better synchronizes Lm invasion events for 2P imaging. 
Mice were placed in a warmed imaging stage and a region of the ileum was 
secured to a plastic coverslip support for 2P imaging. Mice were given 
s.c. fluids for experiments lasting more than 2hr. Time-lapse imaging 
was performed from the luminal surface. Multidimensional datasets 
were rendered and cells were tracked in Imaris (Bitplane) and motility 
was assessed using celltrackR/MotilityLab (2Ptrack.net).

## Data

Columns 1-10 contain the original data; other columns are just processed
versions of the same data.

These columns are:
- Position X, Y, Z: coordinate of a detected cell, floating point number in 
microns
- Unit, Category, Collection: standard output from Imaris; these are always
the same strings ("um", "Spot", "Position" ) and do not contain any information.
- Time: an integer number reflecting the frame in which this coordinate was
measured. Given the frame rate of 250ms, this should be multiplied by 0.25 to 
get time in seconds.
- TrackID: (string) unique identifier of the cell the coordinate belongs to.
- ID: (integer) identifier of the coordinate.
- fill: again a fixed string "fill" with no further information.
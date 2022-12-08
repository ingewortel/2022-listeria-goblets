These files contain tracks for (EGD) Lm-37 and Lm-RT imaged in vitro at
a framerate of 250 ms. 

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
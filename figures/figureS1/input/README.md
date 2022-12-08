Files contain exported tracks of murinized and EGD Lm-RT tracked in vitro at 
a framerate of 250 ms.

Each file is output from Imaris and contains the following columns:

- Position X, Position Y, Position Z: x,y,z coordinates of the tracked cell. 
This is a floating point number, in micrometer.
- Unit, Category, Collection: standard output from Imaris; these are always
the same strings ("um", "Spot", "Position" ) and do not contain any information.
- Time: an integer number reflecting the frame in which this coordinate was
measured. Given the frame rate of 250ms, this should be multiplied by 0.25 to 
get time in seconds.
- TrackID: (string) unique identifier of the cell the coordinate belongs to.
- ID: (integer) identifier of the coordinate.


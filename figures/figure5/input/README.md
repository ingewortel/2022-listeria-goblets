# Neutrophil and Lm tracking data

In the `input/` folder, .rds files are not raw data but contain simulation outputs so that figures 
can be regenerated quickly without having to do the simulation again.

You can open them using readRDS() in R, but all the code used to generate
them is also contained in this repository. See the README in "figures/"
for details.

The `ex_vivo` folder contains the raw data used for panel 5E; see below.

## Experiment

LysM-GFP mice were infected intraluminally with 1x10^8 Lm. At 5hpi, mice were 
sacrificed, ileum explanted, rechallenged with 1x10^8 Lm (BacLight-Red labeled) and 
imaged with 2P microscopy at 100ms time resolution.

Please note that tracking cells here is quite tricky; at 100ms, neutrophil 
motion is dominated by tracking error. By contrast, Lm are moving so fast
that most of them leave the imaging window quickly. 


## Data

Files contain exported tracks of several neutrophils or Lm. Lm were mostly
tracked near neutrophils; the filenames indicate which neutrophil and Lm files
"belong together". 

Each file is output from Imaris and contains two sheets.

"Position" contains the following columns:

- Position X, Position Y, Position Z: x,y,z coordinates of the tracked cell. 
This is a floating point number, in micrometer.
- Unit, Category, Collection: standard output from Imaris; these are always
the same strings ("um", "Spot", "Position" ) and do not contain any information.
- Time: an integer number reflecting the frame in which this coordinate was
measured. Given the frame rate of 100ms, this should be multiplied by 0.1 to 
get time in seconds.
- TrackID: (string) unique identifier of the cell the coordinate belongs to.
- ID: (integer) identifier of the coordinate.

"Speed" contains the following columns:

- Speed, a floating point number reflecting the speed of the cell at a given
time point (in micron/second).
- Unit, Category: strings "um/s" and "Spot" are the same for each row.
- Time, again an integer number reflecting the frame. Should be multiplied with 
0.1 to get time in seconds.
- TrackID: (string) unique identifier of the cell the coordinate belongs to.
- ID: (integer) identifier of the coordinate.






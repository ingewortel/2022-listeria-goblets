# Figure by figure code

These folders contain the code and data to reproduce the figures in the manuscript.
If you're just interested in finding the data, look inside the `input` directory in the
folder corresponding to the figure you want to find data for. If you want to see or 
run the code used to generate the figures, please read the following.

## Prerequisites

### R and python

To use the code, please make sure you have the following installed:

- R (we tested using R version 4.2.1)

- python >v3.6, including the modules "Naked", "numpy", "pandas"
(you only need this if you plan to re-run simulations in bulk, see below)

You can do this manually or if you have conda, run:

```
conda env create -f environment.yml
conda activate listeria
```

Naked is not in conda repositories so still has to be installed: 

```
pip3 install Naked
```

### Other dependencies


- Basic command line tools such as "make", "awk", "bc" etc. On MacOS, look for xcode CLT.
 On Linux, look for build-essential. On Windows, you may not be able to automatically 
 run the code, but you can still find and look through relevant scripts (see below on 
 how to read the Makefiles)
 
- To make the full figure pdfs you will need latex (including the tikz package). 
 
- nodejs and npm, which are needed for simulations in Figure4, Figure5, and some of the 
supplementary figures. See https://nodejs.org/en/download/.

Standard package managers sometimes install incompatible versions of npm and nodejs. 
To avoid this, you can install both at once using nvm:

```
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
nvm install --lts
nvm use --lts
```

### Node modules and R packages

After that, from the command line you can type:

```
make setup
```

This will also install the required node_modules (needed for simulations) and 
check if all the R packages are installed (if not, it will prompt you to install 
them automatically). Alternatively, R packages are listed in Rpackages.txt and can be installed
manually if you prefer. 

If you run into problems installing the package geomtextpath (https://github.com/AllanCameron/geomtextpath), 
try installing harfbuzz and fribidi first:

- deb: libharfbuzz-dev libfribidi-dev (Debian, Ubuntu, etc)
- rpm: harfbuzz-devel fribidi-devel (Fedora, EPEL)
- csw: libharfbuzz_dev libfribidi_dev (Solaris)
- brew: harfbuzz fribidi (OSX)


## How it works

The directories each point directly to the corresponding (supplemental) figure in the
manuscript (some figures are not included if they consisted only of microscopy images,
so if no further code/raw data was used to generate the figure). 

Once you have ensured your prerequisites are in order, you can go to the
directory of a figure, e.g.:

```
cd figure1
```

### Folder contents

Inside this folder you will find some or all of the following:

- `Makefile`, this is an overview you can use to trace back exactly with what 
code and from what data a given figure was created. See below.

- `input/`, a directory with data needed to generate panels in the figure. This is mostly
raw data, but sometimes the simulation outputs are stored here as well for convenience 
(you can also re-generate the simulation outputs yourself but this may take significant 
time; see below). **If you're just interested in the raw data, you should look here.**

- `settings/`, a directory with files with parameter combinations used for any simulations
in the figure. You only need this if you want to re-generate simulations, see below.

- `latex/`, a directory with a latex file that combines all inputs into a pdf of
the figure as it is shown in the manuscript. You only need this if you want to 
automatically re-generate the figure; see below.

- `img/`, a directory with any microscopy images/schematics needed to reconstruct the 
full figure. These are images that were not generated using code so they are just here
to re-generate the entire figure. 


### How to use and read the Makefile

If you have all the prerequisites installed, from the figure directory (e.g. `figure1/`)
you should be able to type:

```
make
```

this will produce a file `figureX.pdf` recreating the figure from the manuscript.

The `Makefile` itself also contains the information on how the figure was generated.
Makefiles have the following general structure:

```
some-target-file.file : dependency1.script dependency2.data | other-stuff
	[recipe]
```

You would read this as follows:

- the file `some-target-file.file` can be reproduced using the script `dependency1.script`
 and any data in `dependency2.data`. 

- The code needed to do so is contained in the "recipe". In principle, you should be able
to run this from the command line and get the same result. But sometimes, the files contain
Makefile shortcuts: "$@" contains the file being made (in this case `some-target-file.file`),
"$<" contains the first dependency file (in this case `dependency1.script`), and
"$^" contains all dependency files before "|" (in this case `dependency1.script dependency2.data` )

- Anything after the "|" typically indicates something that needs to be done first, 
such as generating a directory called "data" or processing/copying data from another figure.

As an example:

The `Makefile` in `figure1` contains the following:

```
figure1.pdf : latex/figure1.pdf
	cp $< $@

latex/figure1.pdf : latex/figure1.tex plots/panelsE-I.pdf
	cd latex && pdflatex figure1.tex
```

So we know that it will create `figure1.pdf` first in the folder `latex/` and then
copy it to the main folder when it is done. But to create `latex/figure1.pdf`, it
first needs to produce `plots/panelsE-I.pdf`.

Further on in the Makefile, we find:

```
plots/panelsE-I.pdf : ../scripts/plotting/compare-temperature-motility.R \
	data/bacteria-37-all.rds data/bacteria-RT-all.rds data/bootstrap-speed-RT-all.rds \
	data/bootstrap-speed-RT-motile.rds data/stepPairs-RT.rds | plots data
	Rscript $^ $@
```

This tells us that we can create plots/panelsE-I.pdf by typing in the commandline:

```
Rscript ../scripts/plotting/compare-temperature-motility.R data/bacteria-37-all.rds data/bacteria-RT-all.rds data/bootstrap-speed-RT-all.rds data/bootstrap-speed-RT-motile.rds data/stepPairs-RT.rds
```

(remember the meaning of "$^" and "$@" as explained above). But before this can happen,
the Makefile first creates directories called "plots" and "data", and it generates the
files `data/something.rds` listed. 

You can then trace back how these files are generated (i.e., by which scripts 
and from which inputs) in the same way. 

### Recreating simulations

In most figures, the simulation outputs are not regenerated by typing `make` because
this might take quite long (except for Figures S5 and S10, for which the simulations
needed to recreate the figure take very little time).

The plots will therefore typically use a file called `input/something.rds`, which 
contains these stored simulation outputs. However, the Makefile also shows you 
how to recreate these simulations if you want to. Any `input/something.rds` is 
matched with a corresponding `data/something.rds` which you can use to regenerate 
the simulation. See the section above on how to use the Makefile, or simply type:

```
make simulation-data
```

in folders of figures that contain simulated data. In the `Makefile`, you can set 
"NSIM" (the number of simulations; this is 20 in the paper but we set it to 3 in the 
Makefile to save time). You can also set MAXPROC, the max number of cores you want to 
allow to run simulations in parallel (please note though that if you choose to 'make' 
in two folders simultaneously, the cores in MAXPROC will add up).

Typically, this works as follows:

- there is a file `settings/something.txt` in which each row reflects a parameter 
combination. The column names are the flags passed on to the simulation (.js) script,
which are passed on with the values as stated in the row. 

- the script `simulation-wrapper.py` uses this to run simulations in parallel, NSIM
times. This is just a helper to automate things. 

- when this process is done, an empty file `progress/something` is generated to indicate that
this is done, and the Makefile will automatically continue to the next step: 
analyzing the simulation outputs and producing the file `data/something.rds`.


If you just want to run a single simulation manually, simply type:

```
node the-simulation-script.js [-any-flags-with value] > myoutput.txt
```

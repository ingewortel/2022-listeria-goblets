.SECONDARY:
.DELETE_ON_ERROR:

all : figure4.pdf

simulation-data : data/BacteriaOnly-events.rds data/AllGoblets.rds

clean : 
	rm -rf figure4.pdf plots data progress && \
	rm -f latex/*.log latex/*.aux latex/*.pdf



# ============= Settings and variables
# path to the folder with the artistoo build scripts.
# To re-do the simulations, you can set NSIM low to save time and still check that
# the scripts work. MAXPROC sets the max number of cores allowed to run simulations
# in parallel. 
pathToArtistoo=../../scripts/artistoo
NSIM=3
MAXPROC=4
NBAC=100


# =============== Full figure
figure4.pdf : latex/figure4.pdf
	cp $< $@

latex/figure4.pdf : latex/figure4.tex plots/panelC1.pdf plots/panelC2.pdf
	cd latex && pdflatex figure4.tex


plots/panelC1.pdf : ../scripts/plotting/plot-temperature-events.R \
	settings/BacteriaOnly-all.txt input/BacteriaOnly-events.rds | plots
	Rscript $^ $(NBAC) invaded $@

plots/panelC2.pdf : ../scripts/plotting/plot-temperature-events-allgoblet.R \
	settings/AllGoblets-all.txt input/AllGoblets.rds | plots
	Rscript $^ $(NBAC) invaded $@



# ************* SIMULATIONS
# Run these only if you want to; the outputs are already saved in the repository.

# ============= Bacteria Only baseline

# Run the simulations in parallel using the python wrapper	
progress/BacteriaOnly-sims : ../scripts/simulations/simulation-wrapper.py \
	../scripts/simulations/full-simulation.js settings/BacteriaOnly-all.txt | progress data/simout
	python3 $^ data/simout $(NSIM) "BacteriaOnly" $(MAXPROC) && touch $@

# Analyze output to get cumulative curves
data/BacteriaOnly-events.rds : ../scripts/analysis/get-all-event-curves.R \
	settings/BacteriaOnly-all.txt progress/BacteriaOnly-sims | data
	Rscript $< settings/BacteriaOnly-all.txt data/simout BacteriaOnly $(NSIM) $@

# ============= Sim with all cells goblet cells

# Run the simulations in parallel using the python wrapper	
progress/AllGoblets-sims : ../scripts/simulations/simulation-wrapper.py \
	../scripts/simulations/full-simulation.js settings/AllGoblets-all.txt | progress data/simout
	python3 $^ data/simout $(NSIM) "AllGoblets" $(MAXPROC) && touch $@

# Analyze output to get cumulative curves
data/AllGoblets.rds : ../scripts/analysis/get-all-event-curves.R \
	settings/AllGoblets-all.txt progress/AllGoblets-sims | data
	Rscript $< settings/AllGoblets-all.txt data/simout AllGoblets $(NSIM) $@



	
# ============= Automatically generate the required folders, and some helper targets.
data : 
	mkdir -p $@

plots :
	mkdir -p $@
	
settings :
	mkdir -p $@
	
progress :
	mkdir -p $@
	
data/simout :
	mkdir -p $@
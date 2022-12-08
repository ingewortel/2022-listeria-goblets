.SECONDARY:
.DELETE_ON_ERROR:

all : figure5.pdf

simulation-data : data/WithPhagocytes-events.rds data/control-outcomes.rds data/outcomes.rds

clean : 
	rm -rf figure5.pdf plots data progress && \
	rm -f latex/*.log latex/*.aux latex/*.pdf



# ============= Settings and variables
# path to the folder with the artistoo build scripts.
# To re-do the simulations, you can set NSIM low to save time and still check that
# the scripts work. MAXPROC sets the max number of cores allowed to run simulations
# in parallel. 
pathToArtistoo=../../scripts/artistoo
NSIM=3
MAXPROC=4


# =============== Full figure
figure5.pdf : latex/figure5.pdf
	cp $< $@

latex/figure5.pdf : latex/figure5.tex plots/panelB.pdf plots/panelC.pdf plots/panelE.pdf
	cd latex && pdflatex figure5.tex

plots/panelB.pdf : ../scripts/plotting/plot-temperature-endstate.R \
	settings/WithPhagocytes-all.txt input/WithPhagocytes-events.rds | plots
	Rscript $^ $@

plots/panelC.pdf : ../scripts/plotting/plot-phag-motility-endstate.R \
	input/outcomes.rds input/control-outcomes.rds | plots
	Rscript $^ $@

plots/panelE.pdf : ../scripts/plotting/plot-speeds-invivo.R \
	data/speeds.csv | plots
	Rscript $^ $@

	
data/neutrophil-tracks.csv : pool-data.R | data
	Rscript $< input/ex_vivo/neutrophils $@
	
data/Lm-tracks.csv : pool-data.R | data
	Rscript $< input/ex_vivo/Lm $@

data/speeds.csv : get-speeds.R data/neutrophil-tracks.csv data/Lm-tracks.csv
	Rscript $^ $@

# ************* SIMULATIONS
# for panels B and C. 
# Run these only if you want to; the outputs are already saved in the repository.

# ============= With phagocytes baseline simulations for panel B

# Run the simulations in parallel using the python wrapper	
progress/WithPhagocytes-sims : ../scripts/simulations/simulation-wrapper.py \
	../scripts/simulations/full-simulation.js settings/WithPhagocytes-all.txt | progress data/simout
	python3 $^ data/simout $(NSIM) "WithPhagocytes" $(MAXPROC) && touch $@

# Analyze output to get cumulative curves
data/WithPhagocytes-events.rds : ../scripts/analysis/get-all-event-curves.R \
	settings/WithPhagocytes-all.txt progress/WithPhagocytes-sims | data
	Rscript $< settings/WithPhagocytes-all.txt data/simout WithPhagocytes $(NSIM) $@

# ============= panel C: 
# in the 'settings' files, every line shows one parameter combination considered. 
# (column names are the flags given to the js script). 

# Run the simulations in parallel using the python wrapper	
progress/VarySpeed-sims : ../scripts/simulations/simulation-wrapper.py \
	../scripts/simulations/full-simulation-with-v0.js settings/VarySpeed-all.txt | progress data/simout
	python3 $^ data/simout $(NSIM) "VarySpeed" $(MAXPROC) && touch $@

# Analyze invasions and phagocytosis at the end of the simulation.
data/outcomes.rds : ../scripts/analysis/get-outcomes.R settings/VarySpeed-all.txt progress/VarySpeed-sims | data
	Rscript $< settings/VarySpeed-all.txt data/simout VarySpeed $(NSIM) $@


# Run the simulations in parallel using the python wrapper	
progress/Control-sims : ../scripts/simulations/simulation-wrapper.py \
	../scripts/simulations/full-simulation-with-v0.js settings/Control.txt | progress data/simout
	python3 $^ data/simout $(NSIM) "Control" $(MAXPROC) && touch $@

# Analyze outcomes for the control
data/control-outcomes.rds : ../scripts/analysis/get-outcomes.R settings/Control.txt progress/Control-sims | data
	Rscript $< settings/Control.txt data/simout Control $(NSIM) $@

	
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
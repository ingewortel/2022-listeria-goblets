.SECONDARY:
.DELETE_ON_ERROR:

all : figureS13.pdf

simulation-data : data/outcomes.rds

# =============== Full figure
figureS13.pdf : latex/figureS13.pdf
	cp $< $@

latex/figureS13.pdf : latex/figureS13.tex plots/panelA-C.pdf plots/panelD-F.pdf
	cd latex && pdflatex figureS13.tex

NGOB=20
# input/outcomes.rds can be reproduced by making data/outcomes.rds (see below).
# input/control-outcomes.rds is the same as for figure5; see that figure for details.
plots/panelA-C.pdf : ../scripts/plotting/plot-events-by-Lmspeed.R input/outcomes.rds | plots
	Rscript $^ $(NGOB) $@

plots/panelD-F.pdf : ../scripts/plotting/plot-events-by-Phspeed.R input/outcomes.rds \
	input/control-outcomes.rds | plots
	Rscript $^ $@

# ************* SIMULATIONS
# Run these only if you want to; the outputs are already saved in the repository.

NSIM=3
MAXPROC=4

# Run the simulations in parallel using the python wrapper	
progress/VarySpeed-sims : ../scripts/simulations/simulation-wrapper.py \
	../scripts/simulations/full-simulation-with-v0.js settings/VarySpeed-all.txt | progress data/simout
	python3 $^ data/simout $(NSIM) "VarySpeed" $(MAXPROC) && touch $@


# Analyze invasions and phagocytosis at the end of the simulation.
data/outcomes.rds : ../scripts/analysis/get-outcomes.R settings/VarySpeed-all.txt progress/VarySpeed-sims | data
	Rscript $< settings/VarySpeed-all.txt data/simout VarySpeed $(NSIM) $@




# ============= Automatically generate the required folders, and some helper targets.

clean : 
	rm -rf figureS13.pdf plots data progress && \
	rm -f latex/*.log latex/*.aux latex/*.pdf

plots :
	mkdir -p $@
	
data : 
	mkdir -p $@
	
data/simout :
	mkdir -p $@

progress :
	mkdir -p $@
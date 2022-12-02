.SECONDARY:
.DELETE_ON_ERROR:

all : figureS6.pdf

simulation-data : data/outcomes.rds

# =============== Full figure
figureS6.pdf : latex/figureS6.pdf
	cp $< $@

latex/figureS6.pdf : latex/figureS6.tex plots/panel.pdf
	cd latex && pdflatex figureS6.tex

NGOB=20
plots/panel.pdf : ../scripts/plotting/plot-events-by-Lmspeed-nophag.R input/outcomes.rds | plots
	Rscript $^ $(NGOB) $@


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
	rm -rf figureS6.pdf plots data progress && \
	rm -f latex/*.log latex/*.aux latex/*.pdf

plots :
	mkdir -p $@
	
data : 
	mkdir -p $@
	
data/simout :
	mkdir -p $@

progress :
	mkdir -p $@
.SECONDARY:
.DELETE_ON_ERROR:

all : figureS11.pdf

simulation-data : data/outcomes-challenge.rds data/outcomes-targets.rds data/outcomes-phagocytes.rds

# =============== Full figure
figureS11.pdf : latex/figureS11.pdf
	cp $< $@

latex/figureS11.pdf : latex/figureS11.tex plots/panelA-D.pdf plots/panelE-H.pdf plots/panelI-L.pdf
	cd latex && pdflatex figureS11.tex


# Required data see also below.
nGoblets=20
NBAC=100
NPH=14
plots/panelA-D.pdf : ../scripts/plotting/plot-events-by-challenge.R input/outcomes-challenge.rds | plots
	Rscript $^ $(nGoblets) $(NBAC) $@

# Plots
plots/panelE-H.pdf : ../scripts/plotting/plot-events-by-targets.R input/outcomes-targets.rds | plots
	Rscript $^ $(nGoblets) $@

plots/panelI-L.pdf : ../scripts/plotting/plot-events-by-nph.R input/outcomes-phagocytes.rds | plots
	Rscript $^ $(nGoblets) $(NBAC) $(NPH) $@


# ************* SIMULATIONS
# make only if you want to, you can keep NSIM low to save time.
MAXPROC=4
NSIM=3

# Run the simulations in parallel using the python wrapper	
progress/VaryChallenge-sims : ../scripts/simulations/simulation-wrapper.py \
	../scripts/simulations/full-simulation.js settings/VaryChallenge-all.txt | progress data/simout
	python3 $^ data/simout $(NSIM) "VaryChallenge" $(MAXPROC) && touch $@

progress/VaryTargets-sims : ../scripts/simulations/simulation-wrapper.py \
	../scripts/simulations/full-simulation.js settings/VaryTargets-all.txt | progress data/simout
	python3 $^ data/simout $(NSIM) "VaryTargets" $(MAXPROC) && touch $@
	
progress/VaryPhagocytes-sims : ../scripts/simulations/simulation-wrapper.py \
	../scripts/simulations/full-simulation.js settings/VaryPhagocytes-all.txt | progress data/simout
	python3 $^ data/simout $(NSIM) "VaryPhagocytes" $(MAXPROC) && touch $@


# Analyze outcomes
data/outcomes-challenge.rds : ../scripts/analysis/get-outcomes.R settings/VaryChallenge-all.txt progress/VaryChallenge-sims | data
	Rscript $< settings/VaryChallenge-all.txt data/simout VaryChallenge $(NSIM) $@

data/outcomes-targets.rds : ../scripts/analysis/get-outcomes.R settings/VaryTargets-all.txt progress/VaryTargets-sims | data
	Rscript $< settings/VaryTargets-all.txt data/simout VaryTargets $(NSIM) $@

data/outcomes-phagocytes.rds : ../scripts/analysis/get-outcomes.R settings/VaryPhagocytes-all.txt progress/VaryPhagocytes-sims | data
	Rscript $< settings/VaryPhagocytes-all.txt data/simout VaryPhagocytes $(NSIM) $@




# ============= Automatically generate the required folders, and some helper targets.

clean : 
	rm -rf figureS11.pdf plots data progress && \
	rm -f latex/*.log latex/*.aux latex/*.pdf

plots :
	mkdir -p $@
	
data : 
	mkdir -p $@
	
data/simout :
	mkdir -p $@

progress :
	mkdir -p $@
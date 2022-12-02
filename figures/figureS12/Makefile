.SECONDARY:
.DELETE_ON_ERROR:

all : figureS12.pdf

simulation-data : data/outcomes-kattach.rds data/outcomes-kphi.rds

# =============== Full figure
figureS12.pdf : latex/figureS12.pdf
	cp $< $@

latex/figureS12.pdf : latex/figureS12.tex plots/panelA-D.pdf plots/panelE-H.pdf
	cd latex && pdflatex figureS12.tex

NPH=14
NBAC=100
BASELINE=51
nGoblets=20

plots/panelA-D.pdf : ../scripts/plotting/plot-events-by-kattach.R input/outcomes-kattach.rds | plots
	Rscript $^ $(nGoblets) $(NBAC) $(BASELINE) $@

plots/panelE-H.pdf : ../scripts/plotting/plot-events-by-kphi.R input/outcomes-kphi.rds | plots
	Rscript $^ $(nGoblets) $(NBAC) $(BASELINE) $@


# ************* SIMULATIONS
NSIM=3
MAXPROC=4

# Run the simulations in parallel using the python wrapper	
progress/VaryAttach-sims : ../scripts/simulations/simulation-wrapper.py \
	../scripts/simulations/full-simulation.js settings/VaryAttach-all.txt | progress data/simout
	python3 $^ data/simout $(NSIM) "VaryAttach" $(MAXPROC) && touch $@

progress/VaryPhi-sims : ../scripts/simulations/simulation-wrapper.py \
	../scripts/simulations/full-simulation.js settings/VaryPhi-all.txt | progress data/simout
	python3 $^ data/simout $(NSIM) "VaryPhi" $(MAXPROC) && touch $@


# Analyze outcomes
data/outcomes-kattach.rds : ../scripts/analysis/get-outcomes.R settings/VaryAttach-all.txt progress/VaryAttach-sims | data
	Rscript $< settings/VaryAttach-all.txt data/simout VaryAttach $(NSIM) $@

data/outcomes-kphi.rds : ../scripts/analysis/get-outcomes.R settings/VaryPhi-all.txt progress/VaryPhi-sims | data
	Rscript $< settings/VaryPhi-all.txt data/simout VaryPhi $(NSIM) $@


# ============= Automatically generate the required folders, and some helper targets.

clean : 
	rm -rf figureS12.pdf plots data progress && \
	rm -f latex/*.log latex/*.aux latex/*.pdf

plots :
	mkdir -p $@
	
data : 
	mkdir -p $@
	
data/simout :
	mkdir -p $@

progress :
	mkdir -p $@
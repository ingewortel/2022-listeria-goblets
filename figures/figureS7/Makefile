.SECONDARY:
.DELETE_ON_ERROR:

all : figureS7.pdf

simulation-data : data/outcomes.rds

# =============== Full figure
figureS7.pdf : latex/figureS7.pdf
	cp $< $@

latex/figureS7.pdf : latex/figureS7.tex plots/panel.pdf
	cd latex && pdflatex figureS7.tex

NGOB=20
plots/panel.pdf : ../scripts/plotting/plot-events-by-kattach-nophag.R input/outcomes.rds | plots
	Rscript $^ $(NGOB) $@


# ************* SIMULATIONS
NSIM=3
MAXPROC=4


# Run the simulations in parallel using the python wrapper	
progress/VaryAttach-sims : ../scripts/simulations/simulation-wrapper.py \
	../scripts/simulations/full-simulation.js settings/VaryAttach-all.txt | progress data/simout
	python3 $^ data/simout $(NSIM) "VaryAttach" $(MAXPROC) && touch $@

progress/clean-filenames : progress/VaryAttach-sims
	cd data && cp -r simout simout2 && \
	cd simout && bash ../../../scripts/analysis/clean-filenames.bash && \
	cd ../.. && touch $@


# Analyze invasions and phagocytosis at the end of the simulation.
data/outcomes.rds : ../scripts/analysis/get-outcomes.R settings/VaryAttach-all.txt \
       progress/clean-filenames progress/VaryAttach-sims | data
	Rscript $< settings/VaryAttach-all.txt data/simout VaryAttach $(NSIM) $@


# ============= Automatically generate the required folders, and some helper targets.

clean : 
	rm -rf figureS7.pdf plots data progress && \
	rm -f latex/*.log latex/*.aux latex/*.pdf

plots :
	mkdir -p $@
	
data : 
	mkdir -p $@
	
data/simout :
	mkdir -p $@

progress :
	mkdir -p $@
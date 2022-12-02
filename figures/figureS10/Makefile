.SECONDARY:
.DELETE_ON_ERROR:

all : figureS10.pdf

# =============== Full figure
figureS10.pdf : latex/figureS10.pdf
	cp $< $@

latex/figureS10.pdf : latex/figureS10.tex plots/panel.pdf
	cd latex && pdflatex figureS10.tex

# Required files are generated below
plots/panel.pdf : ../scripts/analysis/compare-fit.R data/phagocyte-tracks.rds \
	data/phagocyte-model-l400-m20.txt | plots
	Rscript $^ "Neutrophils" 1 $@

# ============= Step 1: Get tracks (saved in celltrackR format) and preprocess 
data/phagocyte-tracks.rds : ../scripts/analysis/getPhagocyteTracksData.R input/phagocytes.csv | data
	Rscript $^ $@ && rm -f QC.pdf featuremap.pdf


# ============= Step 2: Simulate model data
# Phagocytes: seed = 1, lambda act = 400, max act = 20, 1 second per 1MCS
data/phagocyte-model-l400-m20.txt : ../scripts/simulations/phagocyte-for-fitting.js | data
	node $< 1 400 20 1 > $@


# ============= Automatically generate the required folders, and some helper targets.

clean : 
	rm -rf figureS10.pdf plots data progress && \
	rm -f latex/*.log latex/*.aux latex/*.pdf

plots :
	mkdir -p $@
	
data : 
	mkdir -p $@

progress :
	mkdir -p $@
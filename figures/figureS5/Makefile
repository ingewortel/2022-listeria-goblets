.SECONDARY:
.DELETE_ON_ERROR:

all : figureS5.pdf

# =============== Full figure
figureS5.pdf : latex/figureS5.pdf
	cp $< $@

latex/figureS5.pdf : latex/figureS5.tex plots/panel.pdf
	cd latex && pdflatex figureS5.tex

# Required files are generated below
plots/panel.pdf : ../scripts/analysis/compare-fit.R data/bacteria-RT-filtered.rds \
	data/bacteria-model-l40-d60-p0.txt | plots
	Rscript $^ "Listeria" 150 $@


# =============== get data from figure 1 ("make" that one first)

progress/fig1 : | progress
	cd ../figure1 && $(MAKE) data/bacteria-RT-all.rds data/bacteria-37-all.rds data/bacteria-RT-filtered.rds && touch ../figureS1/$@

data/bacteria-RT-filtered.rds :  | data progress/fig1 
	cp ../figure1/data/bacteria-RT-filtered.rds $@
	
# ============= Step 2: Simulate model data

# Fit (using deltaBIC >= 0 as filter for motile bacteria)
# Bacteria: seed = 1, labmda dir = 40, delta_t = 60, p = 0, 150 MCS/second
data/bacteria-model-l40-d60-p0.txt : ../scripts/simulations/bacteria-for-fitting.js | data
	node $< 1 40 60 0 150 > $@






# ============= Automatically generate the required folders, and some helper targets.

clean : 
	rm -rf figureS5.pdf plots data progress && \
	rm -f latex/*.log latex/*.aux latex/*.pdf

plots :
	mkdir -p $@
	
data : 
	mkdir -p $@

progress :
	mkdir -p $@
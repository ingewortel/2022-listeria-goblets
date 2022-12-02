.SECONDARY:
.DELETE_ON_ERROR:

all : figureS2.pdf

clean : 
	rm -rf figureS2.pdf plots data progress && \
	rm -f latex/*.log latex/*.aux latex/*.pdf

# =============== Full figure
figureS2.pdf : latex/figureS2.pdf
	cp $< $@

latex/figureS2.pdf : latex/figureS2.tex plots/panel.pdf
	cd latex && pdflatex figureS2.tex

# script makes all panels at once.
plots/panel.pdf : ../scripts/plotting/plot-bacteria-speed.R data/bacteria-37-all.rds \
	data/bacteria-RT-all.rds | plots
	Rscript $^ $@

# =============== get data from figure 1 ("make" that one first)

progress/fig1 : | progress
	cd ../figure1 && $(MAKE) data/bacteria-RT-all.rds data/bacteria-37-all.rds data/bacteria-RT-filtered.rds && touch ../figureS2/$@

data/bacteria-RT-all.rds :  | data progress/fig1 
	cp ../figure1/data/bacteria-RT-all.rds $@

data/bacteria-37-all.rds :  | data progress/fig1 
	cp ../figure1/data/bacteria-37-all.rds $@


# ============= Automatically generate the required folders, and some helper targets.
data : 
	mkdir -p $@

plots :
	mkdir -p $@
	
progress :
	mkdir -p $@
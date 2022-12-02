.SECONDARY:
.DELETE_ON_ERROR:

all : figure2.pdf

clean : 
	rm -rf figure2.pdf plots data && \
	rm -f latex/*.log latex/*.aux latex/*.pdf

# =============== Full figure
figure2.pdf : latex/figure2.pdf
	cp $< $@

latex/figure2.pdf : latex/figure2.tex plots/panelsHI.pdf
	cd latex && pdflatex figure2.tex

plots/panelsHI.pdf : ../scripts/plotting/plot-figure2-both.R \
	input/fig-2h.csv input/fig-2i.csv | plots
	Rscript $^ $@
	

# ============= Automatically generate the required folders, and some helper targets.
data : 
	mkdir -p $@

plots :
	mkdir -p $@
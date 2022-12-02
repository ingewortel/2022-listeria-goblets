.SECONDARY:
.DELETE_ON_ERROR:

all : figure3.pdf

clean : 
	rm -rf figure3.pdf plots data && \
	rm -f latex/*.log latex/*.aux latex/*.pdf

# =============== Full figure
figure3.pdf : latex/figure3.pdf
	cp $< $@

latex/figure3.pdf : latex/figure3.tex plots/panelsJK.pdf
	cd latex && pdflatex figure3.tex

plots/panelsJK.pdf : ../scripts/plotting/plot-figure3-both.R \
	input/fig-3j.csv input/fig-3k.csv | plots
	Rscript $^ $@
	
# ============= Automatically generate the required folders, and some helper targets.
data : 
	mkdir -p $@

plots :
	mkdir -p $@
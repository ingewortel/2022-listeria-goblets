.SECONDARY:
.DELETE_ON_ERROR:

all : figureS4.pdf

clean : 
	rm -rf figureS4.pdf plots data progress && \
	rm -f latex/*.log latex/*.aux latex/*.pdf

# =============== Full figure
figureS4.pdf : latex/figureS4.pdf
	cp $< $@

latex/figureS4.pdf : latex/figureS4.tex plots/panelC.pdf
	cd latex && pdflatex figureS4.tex

plots/panelC.pdf : ../scripts/plotting/plot-flaA.R input/green-pixels.txt | plots
	Rscript $^ $@



# ============= Automatically generate the required folders, and some helper targets.


plots :
	mkdir -p $@

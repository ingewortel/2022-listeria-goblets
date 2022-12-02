.SECONDARY:
.DELETE_ON_ERROR:

all : figureS1.pdf

clean : 
	rm -rf figureS1.pdf plots data progress && \
	rm -f latex/*.log latex/*.aux latex/*.pdf

# =============== Full figure
figureS1.pdf : latex/figureS1.pdf
	cp $< $@

latex/figureS1.pdf : latex/figureS1.tex plots/panelA.pdf plots/panelB.pdf
	cd latex && pdflatex figureS1.tex
	
plots/panelA.pdf : ../scripts/plotting/mouse-human-speed.R input/egd-mu-speed.csv input/egd-mu-msd.csv | plots
	Rscript $^ $@
	
plots/panelB.pdf : ../scripts/plotting/check-MSD-fit.R data/bacteria-37-all.rds \
	data/bacteria-RT-all.rds data/bacteria-RT-filtered.rds \
	data/bootstrap-MSD-37-all.rds data/bootstrap-MSD-RT-all.rds data/bootstrap-MSD-RT-filtered.rds | plots
	Rscript $^ $@	
	

# =============== get data from figure 1 ("make" that one first)

progress/fig1 : | progress
	cd ../figure1 && $(MAKE) data/bacteria-RT-all.rds data/bacteria-37-all.rds data/bacteria-RT-filtered.rds && touch ../figureS1/$@

data/bacteria-RT-all.rds :  | data progress/fig1 
	cp ../figure1/data/bacteria-RT-all.rds $@

data/bacteria-37-all.rds :  | data progress/fig1 
	cp ../figure1/data/bacteria-37-all.rds $@

data/bacteria-RT-filtered.rds :  | data progress/fig1 
	cp ../figure1/data/bacteria-RT-filtered.rds $@

# ============= bootstrap the msd
# Bootstrapped fits of MSDs to compute motility parameters D and P
msdFit : data/bootstrap-MSD-RT-all.rds data/bootstrap-MSD-RT-filtered.rds data/bootstrap-MSD-37-all.rds

bootstrapN=1000

data/bootstrap-MSD-RT-all.rds : ../scripts/analysis/bootstrap-MSDfit.R data/bacteria-RT-all.rds | data
	Rscript $^ $@ $(bootstrapN)

data/bootstrap-MSD-RT-filtered.rds : ../scripts/analysis/bootstrap-MSDfit.R data/bacteria-RT-filtered.rds | data
	Rscript $^ $@ $(bootstrapN)
	
data/bootstrap-MSD-37-all.rds : ../scripts/analysis/bootstrap-MSDfit.R data/bacteria-37-all.rds | data
	Rscript $^ $@ $(bootstrapN)
	

# ============= Automatically generate the required folders, and some helper targets.
data : 
	mkdir -p $@

plots :
	mkdir -p $@
	
progress :
	mkdir -p $@
.SECONDARY:
.DELETE_ON_ERROR:

all : figure1.pdf

clean : 
	rm -rf figure1.pdf plots data && \
	rm -f latex/*.log latex/*.aux latex/*.pdf

# =============== Full figure
figure1.pdf : latex/figure1.pdf
	cp $< $@

latex/figure1.pdf : latex/figure1.tex plots/panelsE-I.pdf
	cd latex && pdflatex figure1.tex

# =============== INPUT DATA


# read into celltrackR and project to xy plane:
data/bacteria-RT-all.rds : ../scripts/analysis/get-bacteria-tracks-raw.R input/bacteria-RT.csv | data
	Rscript $^ $@

data/bacteria-37-all.rds : ../scripts/analysis/get-bacteria-tracks-raw.R input/bacteria-37.csv | data
	Rscript $^ $@

# =============== FILTER NON-MOTILE

# Filtering step: remove non-motile cells (~32%; see plot)
data/bacteria-RT-filtered.rds : ../scripts/analysis/filter-bacteria-tracks.R data/bacteria-RT-all.rds
	Rscript $^ $@

# =============== MOTILITY STATS

# Bootstrapped speed difference in means
data/bootstrap-speed-RT-all.rds : ../scripts/analysis/bootstrap-speed.R data/bacteria-37-all.rds \
	data/bacteria-RT-all.rds | data
	Rscript $^ "37 RT" 10000 $@

data/bootstrap-speed-RT-motile.rds : ../scripts/analysis/bootstrap-speed.R data/bacteria-37-all.rds \
	data/bacteria-RT-filtered.rds | data
	Rscript $^ "37 RT-M" 10000 $@


# =============== PAIR analysis: directional bias / crowding

# Compute cellpairs and step pairs in a separate script because this takes long.
# For now, save some time by only considering the tracks that have at least one coordinate
# within 50 microns of the center of the imaging window:

data/stepPairs-RT.rds : ../scripts/analysis/pair-analysis.R data/bacteria-RT-filtered.rds
	Rscript $^ "steps" 50 $@


# =============== OVERVIEW ANALYSIS FIGURE

# plot speeds and MSD comparing RT(-m) and 37
plots/panelsE-I.pdf : ../scripts/plotting/compare-temperature-motility.R \
	data/bacteria-37-all.rds data/bacteria-RT-all.rds data/bootstrap-speed-RT-all.rds \
	data/bootstrap-speed-RT-motile.rds data/stepPairs-RT.rds | plots data
	Rscript $^ $@
	

# ============= Automatically generate the required folders, and some helper targets.
data : 
	mkdir -p $@

plots :
	mkdir -p $@
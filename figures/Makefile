



setup : node_modules .Rpck

.Rpck : Rsetup.R Rpackages.txt
	Rscript $^ && touch .Rpck

node_modules : 
	npm install 
	
	

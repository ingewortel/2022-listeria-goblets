library( ggplot2, warn.conflicts = FALSE )
library( grid, warn.conflicts = FALSE )

set_panel_size <- function(p=NULL, g=ggplotGrob(p), width=unit(3, "cm"), height=unit(3, "cm")){
  panel_index_w<- g$layout$l[g$layout$name=="panel"]
  panel_index_h<- g$layout$t[g$layout$name=="panel"]
  g$widths[[panel_index_w]] <- width
  g$heights[[panel_index_h]] <- height
  class(g) <- c("fixed", class(g), "ggplot")
  g
}

#General plotting theme
mytheme <-  theme_bw() +
  theme(
    panel.grid = element_blank(),
    line=element_line(size=2),
    text=element_text(size=7),
    plot.title = element_text(size=7),
    axis.text=element_text(size=7),
    legend.position = c(1,0),
	legend.justification = c(1,0),
	legend.background = element_blank(),
	legend.text = element_text( size=6),
	legend.title = element_text(size=6),
	legend.key.size = unit(4, 'mm'), #change legend key size
    legend.key.height = unit(4, 'mm'), #change legend key height
    legend.key.width = unit(4, 'mm'), #change legend key width
    legend.margin = margin(0.5,1,0.5,0.5,"mm"),
    axis.line.x=element_line(size=0.25),
    axis.line.y=element_line(size=0.25),
    axis.ticks=element_line(size=0.25),
    axis.text.y = element_text(hjust=0),
    strip.text = element_text(size=7),
    strip.background = element_rect(fill=NA,color=NA),
    plot.margin = unit(c(0.1,0.3,0.1,0.1),"cm")#trbl
  )		


#!/bin/bash

PWD=/ssd_home/averissimo/work/rpackages/covid19-de_rki-data/vignettes

rm $PWD/../README.md
rm $PWD/../README_files
sudo -u averissimo -H /usr/local/bin/Rscript -e "rmarkdown::render(input = '$PWD/index.Rmd')"
sudo -u averissimo -H /usr/local/bin/Rscript -e "rmarkdown::render_site('$PWD')"
cp -r $PWD/README* $PWD/../
rm -rf $PWD/README*

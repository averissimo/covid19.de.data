#!/bin/bash

PWD=/ssd_home/averissimo/work/rpackages/covid19-de_rki-data

cd $PWD
git pull
/bin/bash -c "/usr/bin/docker exec f9fce376223b $PWD/render_site.sh"
git add .
git commit --all -m "update (automatic cronjob)"
git push

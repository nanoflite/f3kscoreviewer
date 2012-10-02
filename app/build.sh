#!/bin/bash

middleman build

(
    rm -rf .site
    mkdir .site
    cd .site/
    git clone https://github.com/nanoflite/f3kscoreviewer.git . -b gh-pages
    cp -a ../build/* .
    git add .
    git commit -m"site update"
    git push origin gh-pages
)

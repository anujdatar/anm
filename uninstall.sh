#!/bin/bash

# remove ANM folder
rm -rf ${HOME}/.anm

# remove ANM references from .bashrc
sed '/>>>>> ANM/d;/<<<<< ANM/d;/ANM_DIR/d' -i"anm.bak" a.txt

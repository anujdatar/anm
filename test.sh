#!/bin/bash

# ********* write to file
function write_to() {
	printf "Initializing nvm ...\n"
	# echo dddddd >> a.txt

	bashrc_file="a.txt"

	# create bashrc backup
	cp "$bashrc_file" "$bashrc_file.anm.bak"

	printf '\n>>>>> ANM initialization >>>>>\n' >> $bashrc_file
	printf 'export ANM_DIR="$HOME/.anm"\n' >> $bashrc_file
	printf '[ -s "$ANM_DIR/anm.sh" ] && \. "$ANM_DIR/anm.sh"\n' >> $bashrc_file
	printf '<<<<< ANM initialization <<<<<\n' >> $bashrc_file
}


# ********** delete from file
function delete_from() {
	sed '/>>>>> ANM/d;/<<<<< ANM/d;/ANM_DIR/d' -i"anm.bak" a.txt
}

# write_to
# delete_from

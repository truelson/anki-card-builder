#1/bin/sh

cp -f ./images/* ~/Documents/Anki/User\ 1/collection.media/

bundle exec ./anki_import_file_builder.rb $1 $2

#1/bin/sh

# Exit out if they don't have 3 arguments
if [ $# -ne 4 ] && [ $# -ne 5 ]; then
  echo "Usage: $0 <translate-to-language-code(like 'de')> <word-type(like 'noun')> <word-list-file> <anki-import-file> [--skip-images]"
  exit 1
fi

bundle exec ./anki_import_file_builder.rb $1 $2 $3 $4 $5 && open ./images

#cp -f ./images/* ~/Documents/Anki/User\ 1/collection.media/

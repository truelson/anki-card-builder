#!/usr/bin/env ruby

require 'active_support/inflector'
require 'yaml'
require 'rmagick'
require 'easy_translate'
require 'google-search'
require 'open-uri'
require 'HTMLEntities'

string_lang, word_type, INPUT_FILE_NAME, OUTPUT_FILE_NAME, skip_images = ARGV
LANGUAGE = string_lang.to_sym
WORD_TYPE = word_type.downcase
SKIP_IMAGES = ( skip_images == "--skip-images" )
BATCH_SIZE = 50

CONFIG = YAML::load_file( File.join( __dir__, 'config.yml' ))

# take a list of english words with commas, create list with inflection
def toPluralArray( word_array )
  plural_array = word_array.map { |word| word.pluralize }
end

# take a list of english words with commas, add the, and add inflection
def addThe( word_array )
  the_array = word_array.map { |word| "the #{word}" }
end

def getSingleWordArray( word_set_array )
  if ( WORD_TYPE == 'noun' ) 
    word_set_array.map { |word_set| word_set.scan( /[[:alpha:]]+/ )[1].downcase }
  else
    word_set_array
  end
end

def expandForNoun( word_array )

  plural_array = toPluralArray( word_array )

  the_word_array = addThe( word_array )
  the_plural_array = addThe( plural_array )

  the_word_array.zip( the_plural_array ).map { |pair| pair.join(' - ') }

end

def downloadImage( source_word, foreign_word )
  images = Google::Search::Image.new( :query => foreign_word,
                                      :language => LANGUAGE,
                                      :api_key => CONFIG["google_api_key"],
                                      :as_filetype => :jpg )

  image_url = images.first.uri
  File.open( "images/#{source_word}-#{LANGUAGE}.jpg", "w" ) do |file|
    file.print open( image_url ).read
  end
end

File.open INPUT_FILE_NAME, 'r' do |input_file|
  words = input_file.read.chomp
  word_array = words.split(/,\s*/)

  if ( WORD_TYPE == "noun" )
    source_array = expandForNoun word_array
  elsif ( WORD_TYPE == 'verb' )
    source_array = word_array
  else
    source_array = word_array
  end

  source_array_batches = source_array.each_slice( BATCH_SIZE ).to_a
  encoded_foreign_array_batches = source_array_batches.map do |batch|
    EasyTranslate.translate( batch, :to => LANGUAGE, :key => CONFIG["google_api_key"] )
  end

  encoded_foreign_array = encoded_foreign_array_batches.flatten

  decoder = HTMLEntities.new
  foreign_array = encoded_foreign_array.map do |word_set|
    decoder.decode word_set
  end

  single_foreign_word_array = getSingleWordArray( foreign_array )

  File.open OUTPUT_FILE_NAME, 'w' do |output_file|
    foreign_array.zip( word_array, single_foreign_word_array ).map do |triple|
      puts triple[1], triple[2]
      begin
        downloadImage( triple[1], triple[2] ) unless SKIP_IMAGES
        output_file.write( "<img src=\"#{triple[1]}-#{LANGUAGE}.jpg\" />; #{triple[0]}\n" )
      rescue Exception => e
        puts "ACK! problem setting up the card. Here's the info, then headed to next one..."
        puts e.message
        puts e.backtrace.inspect
      end
    end
  end
end


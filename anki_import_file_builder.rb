#!/usr/bin/env ruby

require 'active_support/inflector'
require 'yaml'
require 'rmagick'
require 'easy_translate'
require 'google-search'
require 'open-uri'

input_file_name, output_file_name = ARGV

CONFIG = YAML::load_file( File.join( __dir__, 'config.yml' ))

# take a list of english words with commas, create list with inflection
def toPluralArray( word_array )
  plural_array = word_array.map { |word| word.pluralize }
end

# take a list of english words with commas, add the, and add inflection
def addThe( word_array )
  the_array = word_array.map { |word| "the #{word}" }
end

def getSingleWord( word_set_array )
  word_set_array.map { |word_set| word_set.scan( /[[:alpha:]]+/ )[1].downcase }
end

def downloadImage( word )
  images = Google::Search::Image.new( :query => word, :as_filetype => :jpg, :size => :small, :api_key => CONFIG["google_api_key"] )
  image_url = images.first.uri
  File.open( "images/#{word}.jpg", "w" ) do |file|
    file.print open( image_url ).read
  end
end

File.open input_file_name, 'r' do |input_file|
  words = input_file.readline.chomp
  word_array = words.split(/,\s*/)
  plural_array = toPluralArray( word_array )

  the_word_array = addThe( word_array )
  the_plural_array = addThe( plural_array )

  english_array = the_word_array.zip( the_plural_array ).map { |pair| pair.join(', ') }
  foreign_array = EasyTranslate.translate( english_array, :to => :german, :key => CONFIG["google_api_key"] )

  single_foreign_word_array = getSingleWord( foreign_array )

  File.open output_file_name, 'w' do |output_file|
    foreign_array.zip( single_foreign_word_array, word_array ).map do |pair|
      output_file.write( "#{pair[0]}; <img src=#{pair[2]}.jpg />\n" )
      downloadImage( pair[1] )
    end
  end
end


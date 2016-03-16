#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# Usage:
#     data.sh [options]
# Options:
#     -l, --lang  : languages file name
#     -f, --file  : output file name
#     -n, --num   : number of lines for each file
# Example:
#     data.sh -l=languages.txt -f=text.tsv -n=1000

lang_file="./languages.txt"
output_file="./text.tsv"
num=1000

xml_dir="./xml_bz2"
text_dir="./text_xml"
format_dir="./tsv"

for i in "$@"; do
  case $i in
    -l=*|--lang=*)
      lang_file="${i#*=}"
    ;;
    -f=*|--file=*)
      output_file="${i#*=}"
    ;;
    -n=*|--num=*)
      num="${i#*=}"
    ;;
    *)
      # unknown option
    ;;
  esac
done

rm -f $output_file
mkdir -p $xml_dir
mkdir -p $text_dir
mkdir -p $format_dir

languages=($(cat $lang_file))
for lang in "${languages[@]}"; do
  echo $lang

  format_file=$format_dir"/"$lang".tsv"
  if [ ! -f $format_file ]; then
    text_file=$text_dir"/"$lang"-text.xml"
    if [ ! -f $text_file ]; then
      xml_file=$xml_dir"/"$lang".xml.bz2"
      if [ ! -f $xml_file ]; then
        echo "downloading..."
        wget "http://download.wikimedia.org/"$lang"wiki/latest/"$lang"wiki-latest-pages-articles.xml.bz2" -O $xml_file
      fi
      if [ ! -f "./WikiExtractor.py" ]; then
        echo "WikiExtractor.py not found in directory!"
        echo "Get it from https://github.com/bwbaugh/wikipedia-extractor"
        break
      fi
      echo "extracting..."
      rm -rf extracted
      bzcat $xml_file | python WikiExtractor.py -cb 10M -o extracted - --no-templates
      find extracted -name '*bz2' -exec bunzip2 -c {} \; > $text_file
      rm -rf extracted
    fi
    echo "preprocessing data..."
    perl -pe 's/\n/ / if !($_ =~ m/<\/doc>/)' $text_file | sed 's/<doc id=\"//' | sed 's/\" url=\"/\t/' | sed 's/\" title=\"/\t/' | sed 's/\">\s*/\t/' | sed 's/\s*<\/doc>//' | sed 's/^/'$lang'\t/' | awk -F'\t' '{ if(NF==5 && length($5)>500) print; }' > $format_file
  fi
  echo "generating data..."
  lc=$(wc -l < $format_file)
  awk -F'\t' 'BEGIN{ "shuf -i 1-'$lc' -n '$num' | sort -nu" | getline n; } NR==n{ print $1"\t"$5; "shuf -i 1-'$lc' -n '$num' | sort -nu" | getline n; }' $format_file >> $output_file

done

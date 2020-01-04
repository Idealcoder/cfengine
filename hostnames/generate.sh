#!/bin/bash
# Outputs a list of candidate hostnames to stdout

candidates=$(
 (xidel https://en.wikipedia.org/wiki/List_of_marine_aquarium_fish_species --css 'table>tbody>tr>td:first-child';
  xidel https://en.wikipedia.org/wiki/List_of_freshwater_aquarium_fish_species --css 'table>tbody>tr>td:first-child';
  xidel https://en.wikipedia.org/wiki/List_of_brackish_aquarium_fish_species --css 'table>tbody>tr>td:first-child';
  xidel https://en.wikipedia.org/wiki/List_of_fish_common_names --css 'div.div-col>ul>li'
 ) | awk '{ gsub(", ", "\n"); print $0}' \
   | awk '{ gsub("\\(",  "\n"); print $0}' \
   | awk '{ gsub("\\)",  "\n"); print $0}' \
   | awk '{ gsub(" or ",  "\n"); print $0}' \
   | awk '{ gsub(" / ",  "\n"); print $0}' \
   | awk '{ gsub("\047s",  ""); print $0}' \
   | awk '{ print tolower($0) }' \
   | awk '{ sub(/[ \t]+$/, ""); print }' \
   | grep -v '&' \
   | awk '{ if (length < 21 && length > 5) print $0  }' \
   | awk '{ gsub(" ", "-"); print $0 }' \
   | sort | uniq -u \
   | rev | sort | rev
)

echo "$candidates"


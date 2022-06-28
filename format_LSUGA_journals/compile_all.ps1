############################################################################
# This script will compile all the article submissions once they are       #
# finished being typeset. Pages will start from a given page and be        #
# continuous between articles.                                             #
#                                                                          #
# Dependencies:                                                            #
#   * comp_knit_xe.ps1 (see my GitHub for script, assumes that it is       #
#                       part of PATH)                                      #
#                                                                          #
# Joshua McNeill - joshua dot mcneill at uga dot edu                       #
############################################################################

# Move to articles directory
set-location "articles"

# Get TeX files
$texFiles = get-childitem *.*tex, *.*nw -name

# Pull start page
$startPage = get-content "..\shared\page.tex"

# Compile each document
foreach ($file in $texFiles) {
  $name, $ext = $file.split(".")
  comp_knit_xe.ps1 $name
  $filePages = pdfinfo "$name.pdf" | Select-String "Pages:\s+(\d+)$"
  $filePages = $filePages.matches.groups[1].value
  $startPage = [int]$startPage + $filePages
  set-content "..\shared\page.tex" $startPage
}

# Return to starting directory
set-location ".."

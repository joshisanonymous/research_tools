############################################################################
# This script will automate the initial steps of formatting submissions    #
# for the journals LCUGA Proceedings and UGA Working Papers in Linguistics #
# but will not be 100% sufficient. Manually go through the resulting       #
# .tex files after running this script.                                    #
#                                                                          #
# Dependencies:                                                            #
#   * pandoc                                                               #
#   * pdfinfo                                                              #
#                                                                          #
# Full process steps:                                                      #
#   1) Place script and submission files into the same directory.          #
#   2) Rename submission files to match the last name of author.           #
#   3) Run script.                                                         #
#   4) Submit the references.txt from each generated directory to          #
#      the text2bib site to obtain .bib files.                             #
#   5) Manually update the mark-up in the .tex files.*                     #
#   6) Update page.tex to be the page on which to start this volume.       #
#   7) Compile .tex files (all in the same dir) using compile_all.ps1.     #
#                                                                          #
# Typical manual editing steps:                                            #
#   1) Keyword search in the doc for each entry in the .bib file to        #
#      adjust mentions to mark-up.                                         #
#      a) If it's already a TeX doc with a .bib, just make sure the cite   #
#         tags are all biblaTeX compliant.                                 #
#   2) Keyword search all ( marks to find separated page number citations  #
#      and replace with correct format, e.g. (p.~#).                       #
#   2) Find and replace all \emph tags to \lexi.                           #
#      a) Double check that each \emph was a lexical item (they usualy     #
#        will be).                                                         #
#      b) When followed by a gloss, they should have the \gloss mark-up.   #
#      c) Do the same for all other \text... tags that may actually be     #
#         lexical items or things like grammatical categories.             #
#   3) Keyword search " and ' to replace with ``...'' and `...' pairs,     #
#      respectively.                                                       #
#   4) Make sure tables and figures look like they did in the original     #
#      submission.                                                         #
#   5) If they're not in the correct locations (e.g., all appended),       #
#      place them in a float in the generally right position with the      #
#      correct float placement flags.                                      #
#   6) Do keyword search for figure and table to identify where mentions   #
#      of figures and tables appear in the text, at which point you should #
#      replace with \label and \ref tags instead and make sure things like #
#      "see below/above/wherever" are accurate directions.                 #
#   7) Make sure all web links in the text are clickable (i.e., they're    #
#      marked up with \href and such).                                     #
#   8) Make sure \title, \shorttitle, \author, \affilication, and          #
#      \contact are all defined.                                           #
#      a) Add \showextra right after \maketitle to make sure said info     #
#         appears.                                                         #
#                                                                          #
# Special note: PowerShell is native to Windows but can also be install    #
#               on Mac in order to run this script.                        #
#                                                                          #
# Joshua McNeill - joshua dot mcneill at uga dot edu                       #
############################################################################

# Text to add
$preamble = "\input{../shared/preamble.tex}"
$referencesBib = "\printbibliography"
$ending = "\end{document}"

# Grab filenames
$filesWord = get-childitem *.doc* -name

# Process
foreach ($file in $filesWord) {
  $name, $extension = $file.split(".")

  # Convert to TeX
  new-item "./$($name)" -itemtype directory
  pandoc --extract-media="./$($name)" "./$($file)" -f docx -t latex -o "./$($name)/$($name).tex"

  # Full text
  $allContent = get-content "./$($name)/$($name).tex"

  # Replace some strings
  $allContent = $allContent -replace "./$($name)/media", "./media"

  # Relevant line numbers to make sections of the text
  $refsStart = $allContent |
               select-string -pattern "^\S*(References|REFERENCES|Bibliography|BIBLIOGRAPHY)\S*$" -casesensitive |
               select-object -expand linenumber
  $refsStart++
  $refsEnd = $refsStart

  foreach ($line in $allContent[$refsStart..($allContent.length)]) {
    if (($previousLine -eq "") -and (-not ($line -match "(\D{2}\d{4}\D{2}|\.)"))) {
      break
    } else {
      $refsEnd++
      $previousLine = $line
    }
  }

  # Portions of text
  $contentPreRefs = $allContent[0..($refsStart - 2)]
  $contentPostRefs = $allContent[$refsEnd..($allContent.length)]
  $referencesPlain = $allContent[$refsStart..($refsEnd - 3)]

  # Remove mark-up from plain references
  $referencesPlain = $referencesPlain -replace "\\emph{", ""
  $referencesPlain = $referencesPlain -replace "}", ""
  $referencesPlain = $referencesPlain -replace "\\", ""
  $referencesPlain = $referencesPlain -replace "~", " "

  # Export files
  set-content "./$($name)/$($name).tex" $preamble, $contentPreRefs, $contentPostRefs, $referencesBib, $ending
  set-content "./$($name)/references.txt" $referencesPlain
}
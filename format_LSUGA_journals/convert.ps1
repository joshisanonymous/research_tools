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
#   4) Submit the <name>.txt from each generated directory to the          #
#      text2bib site to obtain .bib files.                                 #
#   5) Put .bib and media files into /articles subdirectory.               #
#   6) Manually update the mark-up in the .tex files.*                     #
#   7) Update page.tex to be the page on which to start this volume.       #
#   8) Compile .tex files (all in the same dir) using compile_all.ps1.     #
#                                                                          #
# *Typical manual editing steps:                                           #
#   1) Make sure \title, \shorttitle, \author, \affiliation, and           #
#      \contact are all defined.                                           #
#      a) Add \begin{document}, \maketitle, and \showextra to make sure    #
#         said info appears.                                               #
#      b) Add \thispagestyle{empty} immediately after \showextra to remove #
#         the page number from the first page.                             #
#   2) Add \addbibresource to each for references.                         #
#   3) Make sure sections are tagged with \section, \subsection, etc.,     #
#      rather than forced into place/format by other tags.                 #
#   4) Make sure the abstract is in \begin{abstract}..\end{abstract}.      #
#   5) Keyword search in the doc for each entry in the .bib file to        #
#      adjust mentions to mark-up.                                         #
#      a) If it's already a TeX doc with a .bib, just make sure the cite   #
#         tags are all biblaTeX compliant.                                 #
#   6) Regex search \(.*?\d+.*?\) to find separated page number citations  #
#      and replace with correct format, e.g. (p.~#).                       #
#   7) Keyword search " and ' to replace with ``...'' and `...' pairs,     #
#      respectively.                                                       #
#   8) (optional) Find and replace all \emph and \text.. tags with those   #
#      from preamble.tex that indicate the function of the tagged material.#
#   9) Replace \uline tags with the standard \underline.                   #
#  10) Make sure characters not supported by the Charis SIL font are       #
#      tagged with a font that works from preamble.tex.                    #
#      a) {\hangul <text>}                                                 #
#      b) {\greek <text>}                                                  #
#      c) {\chinese <text>}                                                #
#      d) {\arab <text>} (make sure to check \RL tags)                     #
#  11) Make sure tables and figures look like they did in the original     #
#      submission.                                                         #
#      a) If they're not in the correct locations (e.g., all appended),    #
#         place them in a float in the generally right position with the   #
#         correct float placement flags.                                   #
#  12) Do keyword search for figure and table to identify where mentions   #
#      of figures and tables appear in the text, at which point you should #
#      replace with \label and \ref tags instead and make sure things like #
#      "see below/above/wherever" are accurate directions.                 #
#  13) Make sure all web links in the text are clickable (i.e., they're    #
#      marked up with \href and such).                                     #
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

# Grab filenames and create target directory
$filesWord = get-childitem *.doc* -name
new-item "./articles" -itemtype directory

# Process
foreach ($file in $filesWord) {
  $name, $extension = $file.split(".")

  # Convert to TeX
  pandoc --extract-media="./articles" "./$($file)" -f docx -t latex -o "./articles/$($name).tex"

  # Full text
  $allContent = get-content "./articles/$($name).tex"

  # Replace some strings
  $allContent = $allContent -replace "./articles/media", "./media"

  # Relevant line numbers to make sections of the text
  $refsStart = $allContent |
               select-string -pattern "^\S*(References|REFERENCES|Bibliography|BIBLIOGRAPHY)\S*$" -casesensitive |
               select-object -expand linenumber
  $refsStart++
  $refsEnd = $refsStart

  foreach ($line in $allContent[$refsStart..($allContent.length)]) {
    if (($previousLine -eq "") -and (-not ($line -match "(\D{2}\d{4}\D{2}|\.)"))) {
      write-host $refsStart, $refsEnd, $allContent[0]
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
  set-content "./articles/$($name).tex" $preamble, $contentPreRefs, $contentPostRefs, $referencesBib, $ending
  set-content "./articles/$($name).txt" $referencesPlain
}
############################################################################
# This script will automate the initial steps of formatting submissions    #
# for the journals LCUGA Proceedings and UGA Working Papers in Linguistics #
# but will not be 100% sufficient. Manually go through the resulting       #
# .tex files after running this script.                                    #
#                                                                          #
# Dependencies:                                                            #
#   * pandoc                                                               #
#                                                                          #
# Steps:                                                                   #
#   1) Place script and submission files into the same directory.          #
#   2) Rename submission files to match the last name of author.           #
#   3) Run script.                                                         #
#   4) Submit the references.txt from each generated directory to          #
#      the text2bib site to obtain .bib files.                             #
#   5) Manually update the mark-up in the .tex files.                      #
#   6) Compile the documents with XeTeX.                                   #
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

# Grab files and save names depending on file type
$allFiles = get-childitem *.doc*, *.*tex, *.*nw -name
foreach ($file in $allFiles) {
  if ($file -match "docx?$") {
    if ($filesWord -eq $null) {
      $filesWord = $file
    } else {
      $filesWord = $filesWord, $file
    }
  } elseif ($file -match "(tex|nw)$") {
    if ($filesTex -eq $null) {
      $filesTex = $file
    } else {
      $filesTex = $filesTex, $file
    }
  }
}

########################
# For Word submissions #
########################
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
               select-string -pattern "^\S*(References|Bibliography)\S*$" |
               select-object -expand linenumber
  foreach ($line in $allContent[($refsStart + 1)..($allContent.length)]) {
    if (($previousLine -eq "") -and (-not ($line -match "\D\d{4}\D"))) {
      $refsEnd = $allContent |
                 select-string -pattern $line |
                 select-object -expand linenumber
      break
    } else {
      $previousLine = $line
    }
  }

  # Portions of text
  $contentPreRefs = $allContent |
                    select-object -index (0..($refsStart - 2))
  $contentPostRefs = $allContent |
                     select-object -index ($refsEnd..($allContent.length))
  $referencesPlain = $allContent |
                     select-object -index ($refsStart..($refsEnd - 3))

  # Remove mark-up from plain references
  $referencesPlain = $referencesPlain -replace "\\emph{", ""
  $referencesPlain = $referencesPlain -replace "}", ""
  $referencesPlain = $referencesPlain -replace "\\", ""
  $referencesPlain = $referencesPlain -replace "~", " "

  # Export files
  set-content "./$($name)/$($name).tex" $preamble, $contentPreRefs, $contentPostRefs, $referencesBib, $ending
  set-content "./$($name)/references.txt" $referencesPlain
}

#########################
# For LaTeX submissions #
#########################

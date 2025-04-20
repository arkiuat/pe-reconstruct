pe-reconstruct
==============

This repository contains a demo of a project to automate the
restoration/expansion of the long elision (the anupubbasikkhā
peyyāla) common to 11 of the 13 suttas in the Sīlakkhandhavagga of
the Digha Nikāya of the Suttapiṭaka of the Pāli Tipiṭaka (DN 3
through DN 13). Since automating this requires some text substitutions
that are specific to particular texts, this demo is constructed for
Ven. @Sujato's English translations.

Resources
---------

The resources needed to thus reconstruct the 11 suttas DN 3 through
DN 13 are (in addition to the bilara-data JSON files themselves for
each cognate of the sutta) a single script and three simple JSON
files for each sutta, provided as part of this demo.

    ./restore-sutta.raku
    ./map/dn*_pe-map.json
    ./map/en/dn*_pe-subst-en-sujato.json
    ./map/pli/dn*_pe-subst-pli-ms.json

### restore-sutta.raku ###

The script is written in Raku, but I plan to reimplement in Python
if there is interest in this. The only dependency is on a standard
JSON-parsing module: more information on this below. See below also
for information on command-line arguments that the script will accept.

### The pe-map.json files ###

For each sutta, the pe-map.json segment-mapping file is universal
to all six cognates and should work without modification for all
translations that are aligned with SuttaCentral's segment numbering.

The pe-map.json file contains "virtual" segment IDs for the elided
segments of the target sutta, associating each one with the
corresponding segment of DN 2 (the source from which the peyyala
text is restored). Occasionally an elided segment is restored with
the text of a repeated segment from elsewhere within the same sutta,
not from DN2.

The only time this file would need to be updated is when the
segmentation changes, specifically the segment numbering.

### The pe-subst.json files ###

There are some textual substitutions that need to be made in the
DN 2 text for the English translation, mostly subsection numbers
and interlocutor addresses. For interlinear or side-by-side display
of the Pāli text, the interlocutor changes etc. should also be made.
These are provided for by the two pe-subst.json files for each
sutta. Unlike the pe-map.json file, the pe-subst.json files for
English may need to be remade from scratch for each particular
version.

How to run the demo
-------------------
If you can't run the script but want to inspect the results, the
directory 

    ./pe-reconstruct/demo 

contains a pre-generated set of files with the long peyyala expanded.

The way I test this on my system is 

1. download a clone of the bilara-data repository, and then
2. in the same directory, clone the pe-reconstruct repository
3. bilara-data and pe-reconstruct must both be in the same directory
4. cd into the pe-reconstruct directory and run the script 
5. the results will be in pe-reconstruct/reconst

Or to spell it out:

    git clone https://github.com/suttacentral/bilara-data.git
    git clone https://github.com/arkiuat/pe-reconstruct.git
    cd pe-reconstruct
    ./restore-sutta.raku
    ls -l reconst

The script uses relative pathnames via ../bilara-data to read the
original elided versions of the cognate files, which is why
./pe-reconstruct and ./bilara-data must be sister directories, that
is, side-by-side in the same parent directory.

Command-line parameters
-----------------------
If no command-line arguments are supplied, the script reconstructs
expanded version of all six cognates of all eleven suttas.

If you want to generate the reconstructed cognate files for just
one sutta, specify its number on the command line, e. g.:

    ./restore-sutta 12

will only reconstruct (with peyyala expanded) the files for
*Lohiccasutta*. 

If you have made a minor change somewhere or for any other reason
want to regenerate only a single cognate of a single sutta, you can
specify both the sutta-number and the cognate tag on the command
line:

    ./restore-sutta 12 translation

will generate only the expanded translation.json cognate file for
*Lohiccasutta*.

How to install Raku, JSON::Tiny, and zef
----------------------------------------
Of course, you won't be able to run the script in step 3 if you don't have
Rakudo installed, and also the small JSON-parsing module used. (Raku is the
programming language, Rakudo is the current main implementation.)

Directions for this may be found at the following URLs:

https://rakudo.org/downloads
https://raku.land/cpan:MORITZ/JSON::Tiny

You may want to install zef, the standard Raku module installer,
before installing JSON::Tiny.

https://raku.land/zef:ugexe/zef

### Additional information ###

* https://docs.raku.org/ is the official Raku documentation page.
* https://rakudo.org/ has other information about Rakudo.
* https://raku.land/ is a directory of Raku distributions such as modules, etc.
* https://raku.org/ is a one-stop-shop that should link to most of the above.

To Do
=====

Updates to the .JSON files
--------------------------

* So far I'm the only one making decisions about how the pe-map.json
files are constructed, and for some small bits I can see that there
is a case to be made for more than one way to go about things. I
hope that after publishing this demo, the community can rapidly
attain a consensus on these questions. I plan to update the map
files to accord with this consensus as it develops.

* The pe-subst-en-sujato.json files will need to track changes as
Ven. @Sujato revises the published translations. I expect that a
very small percentage of future revisions will require any updates
to the pe-subst-en-sujato.json files.

* If there is interest, I may add pe-subst-\*.json files for other
segment-aligned translations. If I get collaborative support, we may
do this for segment-aligned translations into other languages.

* Because proper support for interlinear and side-by-side display
is the newest feature added before initial publication, I may not
yet have finished constructing all of the pe-subst-pli-ms.json files
correctly. Originally I hadn't intended to touch the Pāli root
text, but once things got to a certain point, it seemed a shame not
to support interlinear and side-by-side display. These will be
updated.

Updates to the script
---------------------

Right now the script is highly specific, with both DN (as domain)
and DN2 (as text-source) hard-coded in. In the next phase I hope
to extend this so that the same script will also handle
elision-restorations in Majjima Nikāya suttas as well, with different
suttas used as source for the material to be restored, so in that
iteration of the project, neither DN or DN2 will be hard-coded in
anymore.

Of course, no peyyala can be restored by this system without
hand-building a pe-map.json file for each individual sutta, and for
the time being, I'm the only one doing that kind of thing.


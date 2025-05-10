#!/usr/bin/env raku
# script to expand the anupubbasikkhā peyyāla in Sujato's translations of DN's Sīlakkhandhavagga
use JSON::Tiny;
my constant @cognates    = <translation html comment root variant reference>;
my constant $RECONST-DIR = 'reconst';  	# relative to . ; prefix '../bilara-data/' if you want that
my %cache;				# cache so we don't read & parse dn2 eleven times

# Takes up to two optional arguments:
#   with one argument, an integer from 3 to 13, restores all cognates of that sutta of DN
#   with a second argument, a string from @cognates, it restores that cognate of that sutta
# Otherwise restores the elision in all 6 cognates of all 11 suttas in question

sub MAIN (Int $sutta-num? where { !$sutta-num.defined or 3 <= $sutta-num <= 13 }, 
          Str $cognate?   where { !$cognate.defined   or $cognate (elem) @cognates } ) {
    my @suttas = 3 .. 13;
    @suttas = $sutta-num, if $sutta-num.defined;
    @cognates = $cognate, if $cognate.defined;    # the comma constructs a one-element list
    for @suttas -> $sut-num {
	my $sut = "dn$sut-num";
	$*ERR.print: $sut;
	my $virtsegs = Map.new( 
	    from-json("./map/{$sut}_pe-map.json".IO.slurp).kv 
	);
	for @cognates -> $cog {
	    reconstruct-cognate($sut, $cog, $virtsegs);
	}
	$*ERR.print: "\n";
    }
}

# reconstruct-cognate: expand the peyyala for one particular cognate and write it to disk unless unchanged
sub reconstruct-cognate (Str $sut, Str $cog, Map $pe-map) {
    my $dn2-path = cognate-pathname('dn2', $cog);
    my $dn2segs;
    if %cache{$dn2-path}.defined {
	$dn2segs = %cache{$dn2-path};
    }
    else {
	unless $dn2-path.IO.e {
	    note "$dn2-path not found"; 
	    next;
	}
	$dn2segs = Map.new( from-json($dn2-path.IO.slurp).kv );	
      # unless $dn2segs.kv { note "cannot parse $dn2-path" }
	%cache{$dn2-path} = $dn2segs; 
    }
    my $sut-path = cognate-pathname($sut, $cog);
    unless $sut-path.IO.e {
	note "$sut-path not found"; 
	next;
    }
    my $suttasegs = Map.new( from-json($sut-path.IO.slurp).kv );
  # unless $suttasegs.kv { note "cannot parse $sut-path" }
    $*ERR.print( ' ', $cog.comb(2,1)[0] );
    my $json = jsonify( 
	expand-peyyala($suttasegs, $dn2segs, $pe-map.Hash, pe-subst($sut, $cog)) 
    );
    for my $reconst-path = $sut-path {
	s| "../bilara-data/$cog" |$RECONST-DIR|;
	s|  ($sut)  |$0_reconstructed|;
      # comment out these next two lines if you want to use the usual bilara subdir structure
      #                              you can also reinsert $cog into the path on the RHS of a s///
       	s| '/en/sujato/sutta/dn' ||;
       	s| '/pli/ms/sutta/dn' ||;
    }
    if $reconst-path.IO.e and $json eqv $reconst-path.IO.slurp {
	$*ERR.print: " unchanged,";
	next;
    }
    $reconst-path.IO.spurt: $json;
}

# expand-peyyala: transform pe-map into the reconstructed version for one particular cognate
sub expand-peyyala (Map $suttacog, Map $dn2cog, Hash $reconst, Map $subst) {
    for $reconst.kv -> $virt, $real { 
	my $source = $dn2cog{$real}:exists ?? $dn2cog !! $suttacog;
	$reconst{$virt} = correct-text($source, $subst, $real);
    }
  # merge unelided segments from $suttacog into the result
    for $suttacog.keys -> $seg-id {
	next if $reconst{$seg-id}:exists;	# don't clobber segments that have already been mapped
 	next if $seg-id ~~ /\-/; 	# exclude hyphenated anchor segments that have been renumbered
	$reconst{$seg-id} = correct-text($suttacog, $subst, $seg-id);
    }
    return $reconst;
}

# correct-text: returns the text of $cog{$seg-id}, corrected according to $subst's specifications
sub correct-text (Map $cog, Map $subst, Str $seg-id) {
    my $text = $cog{$seg-id};
    if $subst{$seg-id}:exists {
	my ($old, $new) = ($subst{$seg-id}).kv;
	$text ~~ s/$old/$new/;
    }
    return $text;
}

# pe-subst: read in the substitutions mapping and return it, if any, otherwise return an empty map
sub pe-subst (Str $sut, Str $cog) {
    my $path;
    given $cog {
	when /translation/ {
	    $path = "./map/en/{$sut}_pe-subst-en-sujato.json";
	}
	when /root/ {
	    $path = "./map/pli/{$sut}_pe-subst-pli-ms.json";
	}
    }
    return $path.defined ?? Map.new( from-json($path.IO.slurp).kv ) !! Map.new();
}

# cognate-pathname computes the pathname of the current cognate
sub cognate-pathname (Str $sut, Str $cog) {
    my @comps;
    given $cog {
	when /root||html||reference||variant/ {
	    @comps = <pli ms>;
	}
	when /translation||comment/ {
	    @comps = <en sujato>;
	}
    }
    s|^|/| for @comps;
    my ($dirpart, $filepart) = @comps.join xx 2;
    $filepart ~~ s:g| '/' |-|;
    $filepart = '' if ($cog ~~ /html||reference/);
    return ( "../bilara-data/$cog", $dirpart, "/sutta/dn/{$sut}_$cog", $filepart, ".json").join;
}

# jsonify: we don't use JSON::Tiny's to-json for output, because not sorted by seg-id and no whitespace
# 	   (I should probably be using a more elaborate library instead, but did this first.)
sub jsonify (Hash $segment) {
    my @json;
    for $segment.keys.sort(&seg-id-cmp) -> $id { 
	next unless $segment{$id}.defined;
	@json.push( (q[  "], $id, q[": "], $segment{$id}, q[",]).join );
    }
    @json.unshift( q[{] );
    @json[*-1] ~~ s/\,$//;
    @json.push( q[}] );
    return @json.join("\n");
}

# seg-id-cmp: comparison routine to sort the lines for output
sub seg-id-cmp (Str $id1, Str $id2) {
    my ($sut1, $seg1) = $id1.split(':');
    my ($sut2, $seg2) = $id2.split(':');
    $*ERR.put: "in sort, comparing segment IDs from different suttas: $id1 & $id2" if $sut1 ne $sut2;
    my @seg1 = $seg1.split('.').map: { .Int };	# coerce Str to Int to get numeric comparison
    my @seg2 = $seg2.split('.').map: { .Int };	# otherwise we'd get lexicographic comparison
    return @seg1 cmp @seg2;
}


# TODO
#
# 1. The current {$s}_pe-subst-pli-ms.json files (to enable reasonable
#    side-by-side and interlinear display) are still just stubs copied
#    from the English ones; need real ones. 
#
# 2. Add a ton of error-checking! Try to anticipate the weird situations 
#    users might get into. Nothing fancy, just write to the error stream
#    with "note". Failing silently sucks.
#
# 3. Might want jsonify's parameter to be a Map, since we don't want it
#    to be modified, but that might mean we need to cast Hash to Map
#    when calling it on a Hash (which is the only way we call it so far,
#    I think)

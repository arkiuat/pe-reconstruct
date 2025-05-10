#!/usr/bin/env raku
# script to convert the *_pe-subst.json files from the assumption that mappings are done before substitutions
#        to assuming the opposite order (replace seg-ids by the seg-ids that they are mapped to)
#
# i. e. we used to do mappings first and then substs, but frequently one line that needed substs would get
# mapped-to by several virtuals. Doing it this way makes the pe-subst.json files smaller.
#
# THIS IS A SCRIPT FOR ONE-TIME-USE. It almost certainly should never need to be run ever again.
# (but I'm glad I kept it around, because I forgot to do it on the half-baked Pali subst files I had
# lying around until days after I thought I was finished with this.)

use JSON::Tiny;

sub MAIN ( Int $sutta-num? where { !$sutta-num.defined or 3 <= $sutta-num <= 13 } ) {
    my @suttas = 3 .. 13;
    @suttas = $sutta-num, if $sutta-num.defined; # the comma constructs a one-element list
    for @suttas -> $sut-num {
      ### uncomment one of the following three lines if for some reason you ever need to run this again
      # my $path = "../en/dn{$sut-num}_pe-subst-en-sujato.json";	# old en production substs
      # my $path = "../pli/dn{$sut-num}_pe-subst-pli-ms.json";		# old pli production substs
      #	my $path = "./{$sut-num}/dn{$sut-num}_pe-subst.json";		# newly produced substs
	$*ERR.print: "$sut-num ";
	my $subst = read-map($path);
	my $mapping = read-map("../dn{$sut-num}_pe-map.json");
	my $new-subst = Hash.new();
	my $new-path = $path.subst(/subst/, 'reverse-subst');

	for $subst.keys -> $virt {
	    if $mapping{$virt}.defined {
		$new-subst{$mapping{$virt}} = $subst{$virt}
	    }
	    else {
		$new-subst{$virt} = $subst{$virt}
	    }
	}
	$new-path.IO.spurt: jsonify($new-subst);
	$*ERR.print: "\n";
    }
}

# read-map: given a path, read & parse JSON text and return the data structure
sub read-map ( Str $path ) {
    unless $path.IO.e {
	note "$path not found"; 
	next;
    }
    return Map.new( from-json($path.IO.slurp).kv );
}


# jsonify: we don't use JSON::Tiny's to-json for output, because not sorted by seg-id and no whitespace
# 	   (This mods restore-sutta's version to be recursive for Associatives but not Positionals.)
sub jsonify (Hash $segment) {
    my @json;
    for $segment.keys.sort(&seg-id-cmp) -> $id { 
	given $segment{$id} {
	    when ! .defined { 
		    next 
	    }
	    when Associative { 
		$segment{$id} = jsonify($segment{$id});
	    }
	    default { 
		$segment{$id} = q["] ~ $segment{$id} ~ q["];
	    }
	}
	next unless $segment{$id}.defined;
	@json.push( (q["], $id, q[": ], $segment{$id}, q[,]).join );
    }
    for @json { s:g/^^/  / }
    @json.unshift( q[{] );
    @json[*-1] ~~ s/\,$//;
    @json.push( q[}] );
    return @json.join("\n");
}

# seg-id-cmp: comparison routine to sort the lines for output
sub seg-id-cmp (Str $id1, Str $id2) {
    my ($sut1, $seg1) = $id1.split(':');
    my ($sut2, $seg2) = $id2.split(':');
    my @seg1 = $seg1.split('.').map: { .Int };	# coerce Str to Int to get numeric comparison
    my @seg2 = $seg2.split('.').map: { .Int };	# otherwise we'd get lexicographic comparison
    return @seg1 cmp @seg2;
}

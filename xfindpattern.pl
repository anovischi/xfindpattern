#!/usr/bin/perl


##########################################################################
#  FILE: xfindpatern.pl
# 
#    This is a Perl script which takes as input a file containing  
#    dictionary definitions that are part of speech (pos) tagged 
#   (with Brill tagger) and will generate patterns with the following format:
#
#    1) N succesive words, N >= 2, N <= 5
#
#    2) N words ... M words, ( ( N > 1 ) || ( M > 1 ) ) && ( N <= 5 ) && ( M <= 5 )
#
#    3) 1 word ... 1 word, al least 1 open class word ( /NNS, /VB, /JJ, /RD ... ) 
#
#    The script print on output the patterns in form:
#
#  <pattern>=<number_of_occurences>
#
#    in a descend order of number of occurences
# 
# Usage:  xfindpattern.pl glosses_file_name
# 
#    This is O(n) version of algorithm.

# 
#   REVISION HISTORY:
#   DATE        VERSION         AUTHOR     REASON FOR MODIFICATION
# |=============|==========|==============|============================
# | Jan 26 2016 | 0.1      | Adrian       | Initial Version
#########################################################################

$nSuccesiveWordsMin = 2;       # the minimum number of words used in searching for N succesive words
$nSuccesiveWordsMax = 5;       # the maximum number of words used in searching for N succesive words

$firstWordsMin = 1;            # the minimum number of first words used in searching for "N words ... M words" pattern
$lastWordsMin = 1;             # the minimum number of last  words used in searching for "N words ... M words" pattern
$firstWordsMax = 6;            # the maximum number of first words used in searching for "N words ... M words" pattern
$lastWordsMax = 6;             # the maximum number of last  words used in searching for "N words ... M words" pattern

$interlivingWordsMNMin = 1;      # the minimum number of interliving  words used in searching for "N words ... M words" pattern
$interlivingWordsMNMax = 7;      # the maximum number of interliving  words used in searching for "N words ... M words" pattern

$interlivingWords11Min = 1;      # the minimum number of interliving  words used in searching for "1 word ... 1 word" pattern
$interlivingWords11Max = 7;      # the maximum number of interliving  words used in searching for "1 word ... 1 word" pattern

$threshold = 3;                # the maximum number of occurences for a pattern to keep it

$wordRegExp = "[^ \t]+";       # the regular expresion used in find a word in a gloss using wordSplit function
$spaceRegExp = "[ \t]+";       # the regular expresion for space

$openClassPosList = " NN NNS VB VBD VBG VBN VBP VBZ JJ JJR JJS RB RBR RBS "; # the open class pos list
$skipPosList = " CC CD DT FW LS SYM UH \$ \" \' \` ( ) , . : ; ";  # the skiped pos list for Nw..mW and 1w..1w  steps
$skipPosListNSucc = " SYM UH \$ \" \' \` ( ) , . : ; ";# the skiped pos list for NSucc  step

# separator is a string which separe the regular expression and the
# number of occurences in the output result

$separator="=";

if ( @ARGV < 1 ) 
{
    die "Wrong number of parameters.";
}

$lcount = 0;          # counter for glosses processed
$lMax = 1;            # the maximum counter value

$lPrintCount = 0;     # counter for printing partial results
$lPrintMax = 10000;   # the maximum number of glosses after we prin partial results

@lines = <>;
for( $l = 0; $l < @lines; $l++ ) {
    $lcount++;
    if ( $lcount >= $lMax ) {
	$ll = $l+1;
	print STDERR "$ll\n";
	$lcount = 0;
    }

    $lPrintCount++;
    if ( $lPrintCount >= $lPrintMax ) {
	$lPrintCount = 0;
	print "======== line $l ==== Partial results ===========\n"; 

	foreach $p ( reverse sort { $pattern{ $a } <=> $pattern{ $b } } keys %pattern ) {
	    if ( $pattern{ $p } >= $threshold ) {
		print "$p$separator".$pattern{ $p }."\n";
	    }
	}
    }

    @word = &wordSplit( $lines[ $l ] );

#   searching N succesive words;

    for( $i = $nSuccesiveWordsMin; $i <= $nSuccesiveWordsMax; $i++ ) {
	for( $j = 0; $j + $i <= @word; $j++ ) {
	    $countPos = 0;
	    $skip = 0;

	    $countPos += &checkPos( $word[ $j ], $openClassPosList );

            $skipPosChecked = &checkPos( $word[ $j ], $skipPosListNSucc );
            $skip = $skip || $skipPosChecked;

	    $patternRegExp = &toRegExp( $word[ $j ] );
	    $patternString = $word[ $j ];
	    for( $k = $j + 1; $k < $j + $i; $k++ ) {
		$countPos += &checkPos( $word[ $k ], $openClassPosList );

                $skipPosChecked = &checkPos( $word[ $k ], $skipPosListNSucc );
                $skip = $skip || $skipPosChecked;

		$patternRegExp = $patternRegExp.$spaceRegExp.&toRegExp( $word[ $k ] );
		$patternString = $patternString." ".$word[ $k ];
	    }

	    if ( ( $countPos > 0 ) && ( $skip == 0 ) ) {
		if ( $lines[ $l ] =~ /$patternRegExp/ ) {
		    $pattern{ $patternString }++;
		}
	    }
	}
    }

#   searching N words ... M words

    for( $i = $firstWordsMin; $i <= $firstWordsMax; $i++ ) {
	for( $j = $lastWordsMin; $j <= $lastWordsMax; $j++ ) {
	    for( $k = $interlivingWordsMNMin; $k <= $interlivingWordsMNMax; $k++ ) {
		for( $m = 0; $m + $i + $k + $j <= @word; $m++ ) {
#                   we check conditions
		    
		    $countPos = 0;
		    $countSkipN = 0;
		    $countSkipM = 0;
		    
		    $countPos += &checkPos( $word[ $m ], $openClassPosList );
		    if ( 0 == &checkPos( $word[ $m ], $skipPosList ) ) {
			$countSkipN++;
		    }
		    
		    $patternRegExp = &toRegExp( $word[ $m ] );
		    $patternString = $word[ $m ];
		    
		    for( $n = $m + 1; $n <= $m + $i - $firstWordsMin; $n++ ) {
			$countPos += &checkPos( $word[ $n ], $openClassPosList );
			
			if ( 0 == &checkPos( $word[ $n ], $skipPosList ) ) {
			    $countSkipN++;
			}

			$patternRegExp = $patternRegExp.$spaceRegExp.&toRegExp( $word[ $n ] );
			$patternString = $patternString." ".$word[ $n ];
		    }
		    
		    $patternRegExp = $patternRegExp.$spaceRegExp."(".$wordRegExp.$spaceRegExp."){".$interlivingWordsMNMin.",".$interlivingWordsMNMax."}";
		    $patternString = $patternString." ... ";
		    
		    $countPos += &checkPos( $word[ $m + $i +$k ], $openClassPosList );
		    
		    if ( 0 == &checkPos( $word[ $m + $i + $k ], $skipPosList ) ) {
			$countSkipM++;
		    }
		    
		    $patternRegExp = $patternRegExp.&toRegExp( $word[ $m + $i + $k ] );
		    $patternString = $patternString.$word[ $m + $i + $k ];
		    
		    for( $n = $m + $i + $k + 1; $n <= $m + $i + $k + $j - $lastWordsMin; $n++ ) {
			$countPos += &checkPos( $word[ $n ], $openClassPosList );

			if ( 0 == &checkPos( $word[ $n ], $skipPosList ) ) {
			    $countSkipM++;
			}
			
			$patternRegExp = $patternRegExp.$spaceRegExp.&toRegExp( $word[ $n ] );
			$patternString = $patternString." ".$word[ $n ];	
		    }
		    if ( ( $countSkipN > $firstWordsMin ) || ( $countSkipM > $lastWordsMin ) ) {
			if ( $countPos > 0 ) {
			    if ( $lines[ $l ] =~ /$patternRegExp/ ) {
				$pattern{ $patternString }++;
			    }
			}
		    }
		}
	    }
	}
    }

#   searching 1 word ... 1 word


    for( $k = $interlivingWords11Min; $k <= $interlivingWords11Max; $k++ ) {
	for( $m = 0; $m + $k + 2 <= @word; $m++ ) {
	    $countPos = 0;
	    $skip = 0;

	    $countPos += &checkPos( $word[ $m ], $openClassPosList );
	    $countPos += &checkPos( $word[ $m + $k + 1 ], $openClassPosList );

            $skipPosChecked1 = &checkPos( $word[ $m ], $skipPosList );
            $skip =  $skip || $skipPosChecked1;

            $skipPosChecked2 = &checkPos( $word[ $m +$k + 1 ], $skipPosList );
            $skip = $skip || $skipPosChecked2;


	    if ( ( $countPos > 0 ) && ( $skip == 0 ) {
		$patternRegExp = &toRegExp( $word[ $m ] );
		$patternString = $word[ $m ];
		
		$patternRegExp = $patternRegExp.$spaceRegExp."(".$wordRegExp.$spaceRegExp."){".$interlivingWords11Min.",".$interlivingWords11Max."}";
		$patternString = $patternString." ... ";
	    
		$patternRegExp = $patternRegExp.&toRegExp( $word[ $m + $k + 1 ] );
		$patternString = $patternString.$word[ $m + $k + 1 ];
	    
		if ( $lines[ $l ] =~ /$patternRegExp/ ) {
		    $pattern{ $patternString }++;
		}
	    }
	}
    }

}

# printing the results:

foreach $p ( keys %pattern ) {
    if ( $pattern{ $p } < $threshold ) {
	delete $pattern{ $p };
    }
}


foreach $p ( reverse sort { $pattern{ $a } <=> $pattern{ $b } } keys %pattern ) {
    print "$p$separator".$pattern{ $p }."\n";
}


#############################################################################
#  FUNCTION: wordSplit
# 
#    splits a sentence into words using $wordRegExp varable
#
#
#
#
#  PARAMETERS:
#  
#    the first parameter is the sentence which must be splited
#
#
#  REVISION HISTORY:
#     DATE         VERSION         AUTHOR     REASON FOR MODIFICATION
#  |=============|==========|==============|============================
#  | Jan 26 2016 |  0.1     |  Adrian      |  Initial version
############################################################################

sub wordSplit
{
    local @word;

    $crtSentence = $_[ 0 ];
    $crtSentence =~ s/\n//g;
    while ( $crtSentence =~ /$wordRegExp/ ) {
	push @word, $&;
        $crtSentence = $';
    }
    @word;
}


#############################################################################
#  FUNCTION: toRegExp
# 
#    replace characters '/', '(',')', '.', '[', ']', '{', '}', 
#                       '*', '+', '|', '?' with 
#
#    '\/', '\(', '\)', '\.', '\[', '\]', '\{', '\}',
#    '\*', '\+', '\|', '?'  in the string;
#
#
#    return the changed string
#
#
#
#
#  PARAMETERS:
#  
#    the first parameter is the string
#
#
#  REVISION HISTORY:
#     DATE         VERSION         AUTHOR     REASON FOR MODIFICATION
#  |=============|==========|==============|============================
#  | Jan 26 2016 |  0.1     |  Adrian      |  Initial version
############################################################################


sub toRegExp {
    local $string;

    $string = $_[ 0 ];

    $string =~ s/\//\\\//g;
    $string =~ s/\(/\\\(/g;
    $string =~ s/\)/\\\)/g;
    $string =~ s/\./\\\./g;
    $string =~ s/\[/\\\[/g;
    $string =~ s/\]/\\\]/g;
    $string =~ s/\{/\\\{/g;
    $string =~ s/\}/\\\{/g;
    $string =~ s/\$/\\\$/g;
    $string =~ s/\^/\\\^/g;
    $string =~ s/\*/\\\*/g;
    $string =~ s/\+/\\\+/g;
    $string =~ s/\|/\\\|/g;
    $string =~ s/\?/\\\?/g;
    
    $string;
}



#############################################################################
#  FUNCTION: checkPos
# 
#    search a word to be tagged as a given pos
#
#    return:
#             1 if the pos is found in pos list
#             0 other case
#
#
#
#  PARAMETERS:
#  
#    the first parameter is the word tagged with some pos
#
#    the second parameter is string which is a list of pos-es separated by space
#
#
#  REVISION HISTORY:
#     DATE         VERSION         AUTHOR     REASON FOR MODIFICATION
#  |=============|==========|==============|============================
#  | Jan 26 2016 |  0.1     |  Adrian      |  Initial version
############################################################################


sub checkPos {
    local $word = $_[ 0 ];
    local $posString = $_[ 1 ];
    local $result = 0;
    local $i;
    local $pos;

    $pos = $word;

    $pos =~ s/.*\///g;

    @posArray = split( /$spaceRegExp/, $posString );

    for( $i = 0; $i < @posArray; $i++ ) {
	if ( $pos eq $posArray[ $i ] ) {
	    $result = 1;
	}
    }

    $result;
}






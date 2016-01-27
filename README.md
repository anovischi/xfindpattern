# xfindpattern
Perl script for finding patterns in a document containing sentences tagged with their part of speech tags (Brill pos tags) (each sentence on a line)

The patterns that are searched for have the following format:

    1) N succesive words, N >= 2, N <= 5

    2) N words ... M words, ( ( N > 1 ) || ( M > 1 ) ) && ( N <= 5 ) && ( M <= 5 )

    3) 1 word ... 1 word, al least 1 open class word ( /NNS, /VB, /JJ, /RD ... ) 

    The script print on output the patterns in form:

  <pattern>=<number_of_occurences>

    in a descend order of number of occurences


Usage: perl <pathToScript>/xfindpattern.pl <posTaggedFile>

Example: perl ./xfindpattern.pl gloss.noun.pos.100.txt


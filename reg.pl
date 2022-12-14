#!/usr/bin/perl
#
# @author Austin Hogan <bitstobreath@users.noreply.github.com>
# @date 2022-12-22
# @license MIT
# @version 0.1.0

use strict;                                                     # throws errors if bad coding practices are found
use warnings;                                                   # throws warning if bad coding practices occur

my $total_args = $#ARGV + 1;                                    # assign total number of arguments
my $regex_operator = "";                                        # initialize var
my $regex_value = "";                                           # initialize var
my $regex_final = "";                                           # initialize var

if ( $total_args == 3 ) {                                       # test for pre-dev option and enable debugging
    if (  $ARGV[2] eq "pre-dev" ) {                             # test if pre-dev
        use re 'debug';                                         # use regex debugging
    }                                                           # (end if)
} elsif ( $total_args != 2 ) {                                  # test if total arguments is not two
    print "This Perl script requires two arguments.";           # print error information
    exit 2;                                                     # exit with error
}                                                               # (end if)

$regex_operator = $ARGV[0];                                     # assign regex string operator to use
$regex_value = $ARGV[1];                                        # assign regex string value to test
$regex_final = qr/$regex_operator/p;                            # qr - convert string to regex with

if ( $regex_value =~ /$regex_final/ ) {                         # create if block to manage numeric output exit for exit
    exit 0;                                                     # regex found match
}                                                               # (end if)

exit 1                                                          # regex failed to find a match

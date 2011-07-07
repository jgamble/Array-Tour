#!/usr/bin/perl
#
use Getopt::Long;
use Data::Dumper;
use Array::Tour qw(:directions);
use Array::Tour::Spiral;

use strict;
use warnings;

require "t/helper.pl";


my($cols, $rows, $lvls) = (5, 5, 1);
my $corner_right = 0;
my $corner_bottom = 0;
my $counterclock = 0;
my $inward = 0;

GetOptions("cols=i" => \$cols,
	"rows=i" => \$rows,
	"lvls=i" => \$lvls,
	"right" => \$corner_right,
	"bottom" => \$corner_bottom,
	"inward" => \$inward,
);

my $spiral = Array::Tour::Spiral->new(
		dimensions => [$cols, $rows, $lvls],
		corner_right => $corner_right,
		corner_bottom => $corner_bottom,
		counterclock => $counterclock,
		inward => $inward);

my @grid = makegrid($spiral);
my $gridstr = join("", @grid);

print "'", $gridstr, "'\n";
print join(", ", $spiral->get_dimensions()), "\n";

print "\n", format_grid(" %s", \@grid), "\n";
exit(0);


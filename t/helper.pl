#!usr/bin/perl
#
# helper.pl
#
use Data::Dumper;

use Array::Tour qw(:directions);
my @b36_seq = ('0'..'9', 'A'..'Z', 'a'..'z');

sub makegrid
{
	my $tour = shift;
	my($width, $height) = $tour->get_dimensions();

	my @grid = ((' ' x $width) x $height);
	my $ctr = 0;

	while (my $cref = $tour->next())
	{
		my @coords = @{$cref};
		substr($grid[$coords[1]], $coords[0], 1) = $b36_seq[$ctr];
		$ctr = ($ctr + 1) % (scalar @b36_seq);
	}
	return @grid;
}

#
# format_grid
#
# @xlvls = format_grid(" %s", \@grid);
# $xstr = format_grid(" %s", \@grid);
#
# Returns a formatted string of all the cell values.  By default,
# the format string is " %04x", so the default output strings will
# be rows of hexadecimal numbers separated by a space.
#
# If called in a list context, returns a list of strings, each one
# representing a level. If called in a scalar context, returns a single
# string, each level separated by a single newline.
#
sub format_grid
{
	my $format = shift;
	my $grid_ref = shift;
	my @levels;
print $format, "\n";
print Data::Dumper->Dump($grid_ref); 
exit(0);
	foreach my $l (0..$lvls)
	{
		my $vxstr = "";
		foreach my $r (0..$rows)
		{
			foreach my $c (0..$cols)
			{
				print "grid[$l][$r][$c] = ", $grid[$l][$r][$c], "\n";
				$vxstr .= sprintf($format, $grid[$l][$r][$c]);
			}
			print ":: $vxstr ::\n";
			$vxstr .= "\n";
		}

		push @levels, $vxstr;
	}

	return wantarray? @levels: join("\n", @levels);
}

1;

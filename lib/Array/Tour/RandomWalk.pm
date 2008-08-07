package Array::Tour::RandomWalk;

use 5.008;
use strict;
use warnings;
use integer;
use base q(Array::Tour);
use Array::Tour qw(:directions :status);

our $VERSION = '0.05';

sub _set
{
	my $self = shift;
	my(%params) = @_;

	#
	# Parameter checks.
	#
	warn "Unknown paramter $_" foreach (grep{$_ !~ /fn_choosedir|start/} (keys %params));
	$params{start} ||= [0, 0, 0];

	#
	# We've got the dimensions, now set up an array.
	#
	$self->_make_array();

	$self->{position} = $self->{start} = $params{start};
	$self->{fn_choosedir} = $params{fn_choosedir} || \&_random_dir;

	$self->{queue} = ();

	return $self;
}

#
# $dir = $tour->direction()
#
# Return the direction we just walked.
#
# Overrides Array::Tour's direction() method.
#
sub direction()
{
	my $self = shift;
	return ($self->{tourstatus} == STOP)? NoDirection: $self->{direction};
}

#
# $coord_ref = $tour->next();
#
# Returns a reference to an array of coordinates.  Returns undef
# if there is no next cell to visit.
#
sub next
{
	my $self = shift;

	return undef unless ($self->has_next());

	my @dir = $self->_collect_dirs();

	#
	# There is a cell to break into.
	#
	if (@dir > 0)
	{
		my $p = $self->{position};

		#
		# If there were multiple choices, save it
		# for future reference.
		#
		push @{ $self->{queue} }, $p if (@dir > 1);

		#
		# Choose a wall at random and break into the next cell.
		#
#		my $choose_dir = $self->{fn_choosedir};
#		my $d = $choose_dir->(\@dir, $self->{position});
		my $d = $self->{fn_choosedir}->(\@dir, $p);
		$self->{direction} = $d;
		$self->_break_through($d);
		++$self->{odometer};
	}
	else	# No place to go, back up.
	{
		if (@{ $self->{queue} } == 0)	# No place to back up, quit.
		{
			$self->{tourstatus} = STOP;
			return undef;
		}

		$self->{direction} = SetPosition;
		$self->{position} = shift @{ $self->{queue} };
	}

#	print "\n********\n", $self->dump_array(), "\n********\n";

	return $self->adjusted_position();
}

#
# Default mechanism to perform the random walk.
#
sub _random_dir
{
	return ${$_[0]}[int(rand(@{$_[0]}))];
}

#
# @directions = $obj->_collect_dirs($c, $r, $l);
#
# Find all of our possible directions to wander through the array.
# You are only allowed to go into not-yet-broken cells.  The directions
# are deliberately accumulated in a counter-clockwise fashion.
#
sub _collect_dirs
{
	my $self = shift;
	my($c, $r, $l) = @{ $self->{position} };
	my $m = $self->get_array();
	my($c_siz, $r_siz, $l_siz) = map {$_ - 1} $self->get_dimensions();
	my @dir;

	#
	# Search for enclosed cells in a partially sorted order,
	# starting from North and going counter-clockwise (Ceiling
	# and Floor will always be pushed last).
	#
	push(@dir, North)    if ($r > 0 and $$m[$l][$r - 1][$c] == 0);
	push(@dir, West)     if ($c > 0 and $$m[$l][$r][$c - 1] == 0);
	push(@dir, South)    if ($r < $r_siz and $$m[$l][$r + 1][$c] == 0);
	push(@dir, East)     if ($c < $c_siz and $$m[$l][$r][$c + 1] == 0);
	push(@dir, Ceiling)  if ($l > 0 and $$m[$l - 1][$r][$c] == 0);
	push(@dir, Floor)    if ($l < $l_siz and $$m[$l + 1][$r][$c] == 0);
	print "Position => [", join(", ", @{$self->get_position()}), "]\n",
		"Can go (", join(", ", (map{$self->direction_name($_)} @dir)), ")\n";
	return @dir;
}

sub _break_through
{
	my $self = shift;
	my($dir) = @_;
	my($c, $r, $l) = @{$self->{position}};
	my $m = $self->get_array();
#	print $self->dump_array();
	$$m[$l][$r][$c] |= $dir;
	($c, $r, $l) = @{$self->_move_to($dir)};
	$$m[$l][$r][$c] |= $self->opposite_direction($dir);
	$self->{position} = [$c, $r, $l];
}

1;
__END__

=head1 NAME

Array::Tour::Random - Class for Array Tours.

=head1 SYNOPSIS

  use Array::Tour::Random qw(:directions);

=head1 PREREQUISITES

Perl 5.6 or later. This is the version of perl under which this module
was developed.

=head1 DESCRIPTION

A simple iterator that will return the coordinates of the next cell if
one were to randomly tour a matrix.

=head2 Tour Object Methods

=head3 new([<attribute> => value, ...])

Creates the object with its attributes. The attributes are:

=over 4

=item dimensions

Set the size of the grid:

	my $spath1 = Array::Tour->new(dimensions => [16, 16]);

If the grid is going to be square, a single integer is sufficient:

	my $spath1 = Array::Tour->new(dimensions => 16);

=item start

I<Default value: [0, 0, 0].> Starting point of the random walk.

=back

=head3 has_next()

Returns 1 if there is more to the tour, 0 if finished.

=head3 next()

Returns an array reference to the next coordinates to use. Returns
undef if the iterator is finished.

=head3 direction()

Returns the current direction as found in the :directions EXPORT tag.
These are the constant values North, West, South, and East.


=head3 reset([<attribute> => value, ...])

Return the internal state of the iterator to its original form.
Optionally change some of the characteristics using the same parameters
found in the new() method.

=head3 opposite()

Return a new object that follows the same path as the original object,
reversing the inward/outward direction.

=head3 describe()

Returns as a hash the attributes of the maze object. The hash may be
used to create a new tour object.

=head3 dimensions()

Returns the value of the dimensions attribute.

=head2 See Also

Games::Maze

=head1 AUTHOR

John M. Gamble may be found at <jgamble@cpan.org>

=cut

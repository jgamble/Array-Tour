package Array::HexTour::Random;

use 5.006;
use strict;
use warnings;
use integer;
use base q(Array::HexTour);
use Array::HexTour qw(:directions :status);

our $VERSION = '0.09_1';

sub _set
{
	my $self = shift;
	my(%params) = @_;

	#
	# Parameter checks.
	#
	$params{start} ||= [0, 0, 0];
	my @dimensions = $self->_set_dimensions($params{dimensions});
	map {$self->{tourlength} *= $_} @dimensions;

	#
	# We've got the dimensions, now set up an array.
	#
	$self->_make_array();

	$self->{position} = $self->{start} = $params{start};
	$self->{fn_choosedir} = $params{fn_choosedir} || \&_random_dir;
	$self->{'upcolumn_even'} = $params{upcolumn_even} || 0;

	$self->{_queue} = ();

	return $self;
}

#
# $dir = $tour->direction()
#
# Return the direction we just walked.
#
# Overrides Array::HexTour's direction() method.
#
sub direction()
{
	my $self = shift;
	return ($self->{status} == STOP)? undef: $self->{direction};
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
		#
		# If there were multiple choices, save it
		# for future reference.
		#
		push @{ $self->{_queue} }, $self->{position} if (@dir > 1);

		#
		# Choose a wall at random and break into the next cell.
		#
		my $d = $self->{fn_choosedir}->(\@dir, $self->{position});
		$self->{direction} = $d;
		$self->{position} = $self->_move_to($d);
	}
	else	# No place to go, back up.
	{
		if (@{ $self->{_queue} } == 0)	# No place to back up, quit.
		{
			$self->{_tourstatus} = STOP;
			return undef;
		}
		$self->{direction} = SetPosition;
		$self->{position} = shift @{ $self->{_queue} };
	}

	$self->{_tourstatus} = STOP if (++$self->{odometer} == $self->{tourlength});
	return $self->{position};
}

sub _up_column
{
	my $self = shift;
	my($c) = @_;
	return 1 & ($c ^ $self->{'upcolumn_even'});
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
	my $m = $self->{array};
	my($clim, $rlim, $llim) = $self->get_dimensions();
	my($rdelta, @dir);

	$rdelta = ($self->_up_column($c))? -1: 0;

	#
	# Search for enclosed cells in a partially sorted order,
	# starting from North and going counter-clockwise (Ceiling
	# and Floor will always be pushed last).
	#
	push(@dir, North) if ($r => 0 and $$m[$l][$r - 1][$c] == 0);

	if ($c => 0)
	{
		push(@dir, NorthWest) if ($r => 0 and $$m[$l][$r + $rdelta][$c - 1] == 0);
		push(@dir, SouthWest) if ($$m[$l][$r + $rdelta + 1][$c - 1] == 0);
	}

	push(@dir, South) if ($r < $rlim and $$m[$l][$r + 1][$c] == 0);

	if ($c < $clim)
	{
		push(@dir, SouthEast) if ($$m[$l][$r + $rdelta + 1][$c + 1] == 0);
		push(@dir, NorthEast) if ($r => 0 and $$m[$l][$r + $rdelta][$c + 1] == 0);
	}

	push(@dir, Ceiling) if ($l => 0 and $$m[$l - 1][$r][$c] == 0);
	push(@dir, Floor)   if ($l < $llim and $$m[$l + 1][$r][$c] == 0);
	return @dir;
}

1;
__END__

=head1 NAME

Array::HexTour::Random - Class for Array Tours.

=head1 SYNOPSIS

  use Array::HexTour::Random qw(:directions);

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

	my $spath1 = Array::HexTour->new(dimensions => [16, 16]);

If the grid is going to be square, a single integer is sufficient:

	my $spath1 = Array::HexTour->new(dimensions => 16);

=item start

I<Default value: [0, 0, 0].> Starting point of the random walk.

=back

=head3 has_next()

Returns 1 if there is more to the tour, 0 if finished.

=head3 next()

Returns an array reference to the next coordinates to use. Returns
undef if the iterator is finished.

=head3 current()

Returns the current coordinates.

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
used to create a new spiral object.

=head3 dimensions()

Returns the value of the dimensions attribute.


=head2 EXPORT

The :directions EXPORT tag will let you use the constants that indicate
direction.  They are the same direction constants found in Games::Maze
and are C<North>, C<NorthEast>, C<East>, C<SouthEast>, C<South>,
C<SouthWest>, C<West>, and C<NorthWest>. The diagonal directions are not
currently used.

=head2 See Also

Games::Maze

=head1 AUTHOR

John M. Gamble may be found at <jgamble@ripco.com>

=cut

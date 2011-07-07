=head1 NAME

Array::HexTour - Base class for Array Tours.

=head1 SYNOPSIS

  #
  # For a new package.  Add extra methods and internal attributes afterwards.
  #
  package Array::HexTour::NewTypeOfTour
  use base qw(Array::HexTour);

  # (Code goes here).

or

  #
  # Make use of the constants in the package. 
  #
  use Array::HexTour qw(:directions);

or

  #
  # Use Array::Tour for its default 'typewriter' tour of the array.
  #
  use Array::Tour;
  
  my $by_row = Array::HexTour->new(dimensions => [24, 80, 1]);

=head1 PREREQUISITES

Perl 5.8 or later. This is the version of perl under which this module
was developed.

=head1 DESCRIPTION

Array::HexTour is a base class for iterators that traverse the cells of a
hexagonal array. This class should provide most of the methods needed for any
type of tour, whether it needs to visit each cell or not, and whether the tour
needs to be a continuous path or not.

Like its cousin Array::Tour, the iterator provides coordinates and directions.
It does not define the array. This leaves the user of the tour object free to
define the form of the array or the data structure behind it without
restrictions from the tour object.

By itself without any subclassing or options, the Array::HexTour class traverses
a simple left-to-right, top-to-bottom typewriter path. There are options to change
the direction or orientation of the path.

=cut

package Array::HexTour;

use 5.005;
use strict;
use warnings;
use integer;

use vars qw(@ISA);
require Exporter;

@ISA = qw(Exporter);

use vars qw(%EXPORT_TAGS @EXPORT_OK $VERSION);
%EXPORT_TAGS = (
	'directions' => [ qw (
		North NorthWest West SouthWest Ceiling
		South SouthEast East NorthEast Floor
	)],
	'status' => [ qw (TOURSTART TOURING TOURSTOP)]
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'directions'} }, @{ $EXPORT_TAGS{'status'} } );

$VERSION = '0.09_1';

#
# The directions that we can travel, including our "null" direction
# equivalent "NoDirection" and a suddon position change indicator "LEAP".
#
use constant NoDirection => 0x0000;
use constant North       => 0x0001;	# 0;
use constant NorthWest   => 0x0002;	# 1;
use constant West        => 0x0004;	# 2;
use constant SouthWest   => 0x0008;	# 3;
use constant Ceiling     => 0x0010;	# 4;
use constant South       => 0x0020;	# 5;
use constant SouthEast   => 0x0040;	# 6;
use constant East        => 0x0080;	# 7;
use constant NorthEast   => 0x0100;	# 8;
use constant Floor       => 0x0200;	# 9;
use constant LEAP        => 0x8000;	# 15;

#
# {_tourstatus} constants.
#
use constant TOURSTART	=> 0;
use constant TOURING	=> 1;
use constant TOURSTOP	=> 2;


=head2 Tour Object Methods

=head3 new([<attribute> => value, ...])

Creates the object with its attributes.

Subclasses may add their own attributes.  Since attributes are set using
the internal method _set(),  it's recommended that
subclasses do not override new(). Instead, they merely need to provide
their own _set() method to handle their own attributes.

Four attributes start out available from the base class, C<dimensions>,
C<offset>, C<position>, and C<start>.

These four attributes are automatically set before calling the C<_set()>
method:

=over 4

=item dimensions

I<Default value: [1, 1, 1].> Provide the size of the array:

    my $spath1 = Array::HexTour->new(dimensions => [16, 16]);

The B<dimensions> attribute is pretty forgiving.  In the example above, a
third dimension of 1 will be added automatically.  Likewise, if you only
want a single square, this will be sufficient:

    my $spath1 = Array::HexTour->new(dimensions => 16);

The attribute will detect the single dimension, duplicate it, and add the
third dimension of 1.  You will have the same dimensions as the previous
example.

=item offset

I<Default value: [0, 0, 0].> The coordinate of the upper left corner.
Calls to get_coordinates() will return the position adjusted by the value in C<offset>.

=item start

I<Default value: [0, 0, 0].> The starting position of the tour,
but may begin with different coordinates depending upon the child class.

=item position

The current position of the iterator in the array.

=item odometer

I<Starting value: 0.> The number of cells visited thus far.

=item tourlength

I<Default value: number of cells in the array.> The total number of cells
to visit. This is sometimes used to determine the endpoint of the tour.

=item tourstatus

Initially set to B<TOURSTART>.  The remaining _tourstatus values (found with
the export tag C<:status>) are B<TOURING> and B<TOURSTOP>.

=item array

I<default value: undef.>  A reference to an internal array.  Some sub-classes
need an internal array for bookkeeping purposes.  This is where it will go.
The method _make_array() will create an internal array for a sub-class if it is
needed.

=back

=head3 next()

Returns an array reference to the next coordinates to use. Returns
undef if the iterator is finished.

    my $ctr = 1;
    my $tour = Array::HexTour::Spiral->new(dimensions => 1024);

    while (my $cref = $tour->next())
    {
        my($x_coord, $y_coord, $z_coord) = @{$cref};
        $grid[$y_coord, $x_coord] = isprime($ctr++);
    }

The above example generates Ulam's Spiral L<http://en.wikipedia.org/wiki/Ulam_spiral>
in the array @grid.

=head3 has_next()

Returns 1 if there is more to the tour, 0 if finished.

=head3 current()

Returns the current coordinates.

=head3 direction()

Returns the current direction as found in the :directions EXPORT tag.

=head3 reset([<attribute> => value, ...])

Return the internal state of the iterator to its original form.
Optionally change some of the characteristics using the same parameters
found in the new() method.

=head3 describe()

Returns as a hash the attributes of the tour object. The hash may be
used to create a new spiral object.

=head3 get_dimensions()

Returns the value of the dimensions attribute.

=head2 Internal Tour Object Methods

=head3 _set_dimensions()

    my @dims = Array::HexTour->new(dimensions => [16, 16]);

If the grid is going to be square, a single integer is sufficient:

    my @dims = Array::HexTour->new(dimensions => 16);

In both cases, the C<dimensions> attribute is set with a reference to
a three dimensional array.  The third dimension is set to 1 if it is
unspecified.

=cut

#
# new
#
# Creates the object with its attributes.  Valid attributes
# are listed in the %valid hash.
#
sub new
{
	my $class = shift;
	my $self = {};

	#
	# We are copying from an existing Tour object?
	#
	if (ref $class)
	{
		if ($class->isa("Array::HexTour"))
		{
			$class->_copy($self, @_);
			return bless($self, ref $class);
		}

		warn "Attempts to create an Array Touring object from a '",
			ref $class, "' object fail.\n";
		return undef;
	}

	#
	# Starting from scratch.
	#
	bless($self, $class);
	my %attributes = @_;
	$self->_set_dimensions(%attributes);
	$self->_set_offset(%attributes);
	$self->{position} = [0, 0, 0];
	$self->{start} = [0, 0, 0];
	$self->{_array} = undef;
	$self->{_tourlength} = 1;
	map {$self->{_tourlength} *= $_} $self->get_dimensions();
	$self->{_tourstatus} = TOURSTART;
	$self->{_odometer} = 0;
	$self->_set(@_);

	return $self;
}

#
# $self->_set(%attributes);
#
# Set the attributes that were passed in via new().
# This one's pretty minimal because the attributes
# that we care about in this class are already set.
#
sub _set()
{
	my $self = shift;
	my(%params) = @_;

	return $self;
}

#
# $tour->reset();
#
# Reset the iterator, with optional changes.
#
sub reset
{
	my $self = shift;
	my %newargs = @_;

	my %params = $self->describe();
	$params{position} = [0, 0, 0];
	$params{_tourlength} = 1;
	$params{_tourstatus} = TOURSTART;
	$params{_odometer} = 0;
	map {$params{$_} = $newargs{$_}} keys %newargs;

	return $self->_set(%params);
}

sub has_next
{
	my $self = shift;
	return ($self->{_tourstatus} == TOURSTOP)? 0: 1;
}

sub current
{
	my $self = shift;
	return $self->{position};
}

#
# @dimensions = $self->get_dimensions();
#
# Return a reference to the dimension of the array.
#
sub get_dimensions
{
	my $self = shift;
	return @{ $self->{dimensions} };
}

#
# $dir = $tour->direction()
#
# Return the direction we just walked.
#
sub direction
{
	my $self = shift;
	return (${$self->{position}}[0] == 0)? NoDirection: East;
}

#
# $dir = $tour->opposite_direction()
#
# Return the direction back from where we just walked.
#
sub opposite_direction
{
	my $self = shift;
	my $dir = $self->direction();
	return NoDirection if ($dir == NoDirection);
	return ($dir <=  Ceiling )? ($dir << 5): ($dir >> 5);
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

	#
	# Set up the conditions for the pacing.
	#
	if ($self->{_tourstatus} == TOURSTART)
	{
		$self->{_tourstatus} = TOURING;
	}
	else
	{
		#
		# Move to the next cell, checking to see if we've
		# reached the end of the row/plane/cube.
		#
		my($dim, $lastdim) = (0, scalar @{$self->{dimensions}});
		while ($dim < $lastdim and ${$self->{position}}[$dim] == ${$self->{dimensions}}[$dim] - 1)
		{
			${$self->{position}}[$dim++] = 0;
		}
		${$self->{position}}[$dim] += 1 unless ($dim == $lastdim);
	}

	$self->{_tourstatus} = TOURSTOP if (++$self->{_odometer} == $self->{_tourlength});
	return $self->_get_coords();
}

#
# describe
#
# %attributes = $obj->describe();
#
# Returns as a hash the attributes of the object.
# This may be used as a parameter to new objects.
#
sub describe
{
	my $self = shift;
	return map {$_, $self->{$_}} grep(/^[a-z]/, keys %{$self});
}

sub get_offset
{
	my $self = shift;
	return $self->{offset};
}

#
# $self = $self->_set_dimensions($params);
#
# Sets the {dimensions} attribute of the object to an
# array reference.  If a value N is provided instead of
# an array reference, an NxN square array is created.
#
# In all cases, the reference returned has at least three dimensions.
# The third dimension is 1 by default.
#
sub _set_dimensions
{
	my $self = shift;
	my(%params) = @_;
	my $dim = $params{dimensions} || [1, 1, 1];

	my @dimensions;

	if (ref $dim eq 'ARRAY')
	{
		@dimensions = map {$_ ||= 1} @{$dim};
		push @dimensions, 1 if (@dimensions < 1);
		push @dimensions, $dimensions[0] if (@dimensions < 2);
	}
	else
	{
		#
		# Square grid if only one dimension is defined.
		#
		@dimensions = ($dim) x 2;
	}
	push @dimensions, 1 if (@dimensions < 3);
	$self->{dimensions} = \@dimensions;

	return $self;
}

#
# @offsets = _set_offset($offsetref);
#
# Set the offset. This method extends the offset array by zeros
# to match the size of the dimensions array, so the _set_dimensions()
# method must be called first.
#
sub _set_offset
{
	my $self = shift;
	my(%params) = @_;
	my $offsetref = $params{offset} || [1, 1, 1];

	$self->{offset} = $offsetref;

	my $dims = scalar $self->get_dimensions();
	my $offsets = scalar @{$self->{offset}};
	push @{$self->{offset}}, (0) x ($dims - $offsets) if ($dims > $offsets);
	return @{$self->{offset}};
}

#
# $self->_make_array();
#
# Make an internal array for reference purposes.
#
sub _make_array
{
	my $self = shift;
	my($rows, $cols, $lvls) = map {$_ - 1} @{$self->get_dimensions()};

	my $m = $self->{_array} = ([]);
	foreach my $l (0..$lvls)
	{
		foreach my $r (0..$rows)
		{
			foreach my $c (0..$cols)
			{
				$$m[0][$r][$c] = 0;
			}
		}
	}
	return $self;
}

#
# $arrayref = $self->get_array()
#
# Return a reference to the internally generated array.
#
sub get_array
{
	my $self = shift;
	$self->_make_array() unless (defined $self->{_array});
	return $self->{_array};
}

#
# $position_ref = $self->_get_coords();
#
# Return a reference to an array of coordinates
# that are created from the position plus the
# offset.
#
sub _get_coords
{
	my $self = shift;

	my @position = @{ $self->{position} };
	my @offset = @{ $self->{offset} };
	map {$position[$_] += $offset[$_]} (0..$#position);
	return \@position;
}

#
# [$c, $r, $l] = $self->_move_to($direction);
#
# Return a new position depending upon the direction taken.
#
sub _move_to
{
	my $self = shift;
	my($dir) = @_;
	my($c, $r, $l) = @{ $self->{position} };

	++$r if ($dir == North);
	--$r if ($dir == South);
	++$c if ($dir & (East | NorthEast | SouthEast));
	--$c if ($dir & (West | NorthWest | SouthWest));
	++$l if ($dir == Floor);
	++$l if ($dir == Ceiling);

	#
	# Did we go upwards or downwards on a diagonal?
	# Depends on the direction *and* the column.
	#
	if ($self->_up_column($c))
	{
		--$r if ($dir & (NorthWest | NorthEast));
	}
	else
	{
		++$r if ($dir & (SouthWest | SouthEast));
	}

	return [$c, $r, $l];
}

#
# $class->_copy($self);
#
# Duplicate the iterator.
#
sub _copy
{
	my($other, $self) = @_;
	foreach my $k (keys %{$other})
	{
		$self->{$k} = $other->{$k};
	}
}

1;
__END__

=head2 Methods expected to be provided by the derived class.

These methods exist in the base class, but don't do much that is
useful. The deriving class is expected to override these methods.

=head3 _set()

Take the parameters provided to new() and use them to set the
attributes of the touring object.

=head2 EXPORT

The :directions EXPORT tag will let you use the constants that indicate
direction.  They are the directions C<North>, C<NorthEast>, C<East>,
C<SouthEast>, C<South>, C<SouthWest>, C<West>, and C<NorthWest>.

The :status EXPORT tag has the values for the running state of the
iterator.

=head2 See Also

=head1 AUTHOR

John M. Gamble may be found at <jgamble@ripco.com>

=cut

#!/usr/bin/perl -w
#
# Imagemap.pm -- interpret NCSA imagemap in CGI program
#
# $Id: Imagemap.pm,v 1.3 1996/03/02 07:11:04 mike Exp $
#
# Copyright (c) 1996 Michael J. Heins. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# This module adapted from the Perl imagemap program originally
# written by:
#
#     V. Khera <khera@kciLink.com>  7-MAR-1995
#

=head1 NAME

CGI::Imagemap.pm - imagemap behavior for CGI programs

=head1 SYNOPSIS

  use CGI::Imagemap;
 
  $map = new CGI::Imagemap;
  $map->setmap(@map);
  $action = $map->action($x,$y);
 
-- or --

  use CGI::Imagemap 'action_map';
  
  $action = action_map($x,$y,@map);

=head1 DESCRIPTION

CGI::Imagemap allows CGI programmers to place TYPE=IMAGE form fields on
their HTML fill-out forms, with either client-side or server-side maps
emulated.

The imagemap file follows that of the NCSA imagemap program.  Each point
is an x,y tuple.  Each line in the map consists of
one of the following formats.  Comment lines start with "#".

  circle action center edgepoint
  rect action upperleft lowerright
  point action point
  poly action point1 point2 ... pointN
  default action

Using "point" and "default" in the same map makes no sense. If "point"
is used, the action for the closest one is selected.

To use CGI::Imagemap, define an image submit map on your form with
something like:

   <input type=image name=mv_todo
        SRC="image_url">

You can pass a "client-side" imagemap like this:

   <input type="hidden" name="todo.map"
   		value="rect action1 0,0 25,20">
   <input type="hidden" name="todo.map"
   		value="rect action2 26,0 50,20">
   <input type="hidden" name="todo.map"
   		value="rect action3 51,0 75,20">
   <input type="hidden" name="todo.map"
   		value="default action0">

If the @map passed parameter contains a NUL (\0) in the first array
position, the map is assumed to be null-separated and @map is built
by splitting it.  This allows a null-separated todo.map with
multiple values (parsed by a cgi-lib.pl or the like) to be
referenced.

All of the following examples assume the above definitions in your
form.

=head2 Static Methods

CGI::Imagemap allows the export of two routines, I<action_map> and
I<map_untaint>.   If you choose to use CGI::Imagemap statically, call the
module with:

  use CGI::Imagemap qw(action_map map_untaint);

=over 4

=item action_map(x,y,map)

We are assuming the map definition above, with the I<type=image>
variable named F<todo>, and the map in I<todo.map>. You can pass the map
in one of two ways.  The first is compatible with the CGI.pm (or CGI::*)
modules, and passes the map as an array:

    $query = new CGI;
    my $x = $query->param('todo.x');
    my $y = $query->param('todo.y');
    my $map = $query->param('todo.map');
    $action = action_map($x, $y, $map);

If you are using the old I<cgi-lib.pl> library, which places multiple
instances of the same form variable in a scalar, separated by null (\0)
characters, you can do this:

    ReadParse(*FORM);
    my $x = $FORM{'todo.x'};
    my $y = $FORM{'todo.y'};
    my $map = $FORM{'todo.map'};
    $action = action_map($x, $y, $map);

=item map_untaint($untaint)

If you are running with taint checking, as is suggested for CGI programs,
you can use map_untaint(1) to set map untainting on a global basis. 
(If using class methods, each has its own instance of untainting).

It ensures all characters in the action fit pattern of [-\w.+@]+,
meaning alphnumerics, underscores, dashes (-), periods, and the @ sign.
It also checks the methods (rect,poly,point,default,circle) and ensures
that points/tuples are only integers.  Once that is done, it untaints
the passed form variables.

  map_untaint(1);    # Turns on untainting
  map_untaint('yes');# Same as above

  map_untaint(0);    # Disable untainting
  map_untaint('no'); # Same as above
    
  $status = map_untaint(); # Get status

Default is no untainting.

=back

=head2 Class Methods

The class methods for CGI::Imagemap are much the same as above, with the
exception that multiple imagemaps are then maintained by the module, with
full independence. The following method definitions assume the CGI::Form
module is being used, like this:

    use CGI::Form;
    use CGI::Imagemap;

    $query  = new CGI::Form;
    $map    = new CGI::Imagemap;

=over 4

=item setmap(@map)

This sets the map for the instance.

    $map = new CGI::Imagemap;
    $map->setmap($query->param('todo.map'));


=item addmap(@map)

This adds a new map action specification I<to the current map>.

  $map->addmap('point action5 3,9'));

=item action(x,y)

This finds the action, based on the active map and the values of x and y, 

  $x = $query->param('todo.x');
  $y = $query->param('todo.y');
  $action = $map->action($x, $y);

=item untaint()

Sets, unsets, or returns the taint status for the instance.

  $map->untaint(1);       # Turns on untainting
  $map->untaint('yes');   # Same as above
  $map->untaint(1);       # Disables untainting
  $map->untaint('yes');   # Same as above
  $status = $map->untaint(); # Get status


=item version()

Returns the version number of the module.

=back

=head1 EXAMPLE

A couple of self-contained examples are included in the CGI::Imagemap
package.  They are:

  testmap     -  Uses the CGI::Form module
  testmap.old -  Uses the old cgi-lib.pl

=head1 BUGS

The untainting stuff is not totally independent -- threading might
not work very well.  This can be fixed if it is important -- in the
CGI world, I doubt it.

=head1 AUTHOR

Mike Heins, Internet Robotics, <mikeh@iac.net>

=head1 CREDITS

This work is heavily kited from the Perl imagemap program originally
written by V. Khera <khera@kciLink.com>.

=cut

package CGI::Imagemap;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(action_map map_untaint);
$VERSION = '1.00';
use Carp;
use strict;

# global variables
my $Action = "";
my $minDistance = -1;
my $Untaint = 0;

sub new { 
	my $class = shift;
	return bless {UNTAINT => 0}, $class;
}

sub setmap {
	my $self = shift;
	$self->{IMAP} = [ @_ ];
	return @_;
}

sub version {
	my $self = shift;
	return $CGI::Imagemap::VERSION;
}

sub action {
	my $self = shift;
	my ($x,$y) = @_;
	my $savetaint = map_untaint();

	$Untaint = $self->untaint();

	my $action = action_map($x,$y,@{$self->{IMAP}});

	$Untaint = $savetaint;

	return $action;
}

sub addmap {
	my $self = shift;
	push @{$self->{IMAP}}, @_;
	return @{$self->{IMAP}};
}

# action_map is called with the X and Y value of the map, plus the map
# $map[0] can be a null-separated map
	
sub action_map {
	my($x,$y,@map) = @_;
	my($matched,$method,$action,$points);

	unless(@map) {
		carp "No map sent";
		return undef;
	}

	$Action = '';

	if($map[0] =~ /\0/) {
		@map = split /\0/, $map[0];
	}

	my $query = "$x,$y";
	unless ($query =~ m/(\d+),(\d+)/) {
		carp "Wrong arguments; browser may not support image submits";
		return undef;
	}
	elsif ($Untaint) {
		$query = "$1,$2";
	}

	for (@map) {
		chomp;
		next if (m/^\#/ || m/^\s*$/); # skip comments and blank lines
		($method,$action,$points) = split(/ /,$_,3);

		$points = '' unless defined $points;
		if($Untaint) {
			my $pts = '';
			$method = lc $method;
			$method =~ /(rect|default|point|poly|circle)/ or
				do {
					carp "Malformed imagemap: $method unknown";
					return undef;
				};
			$method = $1;
			$action =~ /([-\w.+@]+)/;
			$action = $1;
			while ($points =~ s/(\d+),(\d+)//) {
				($pts = "$1,$2", next) unless $pts;
				$pts .= " $1,$2";
			}
			$points = $pts;
		}


		eval("\$matched = &pointIn_${method}('$action','$query','$points');");
		if ($@ ne "") {
			carp "Malformed imagemap: $method unknown";
			return undef;
		}
		last if $matched;
	}

	if ($Action eq "") {
		# if we have not set $Action by this time, there is no match in the
		# given set of shapes.  Just return undef and let the default in
		# the program do the work
		return undef;
	}
	else {
		return $Action;
	}
}

# Returns current value if passed no param
# Otherwise sets globally 
sub map_untaint {
	my $untaint = shift;

	unless(defined $untaint) {
		return $Untaint;
	}

	if(_is_yes($untaint)) {
		$Untaint = 1;
	}
	else {
		$Untaint = 0;
	}
	$Untaint;
}

sub untaint {
	my $self = shift;
	my $untaint = shift;

	unless(defined $untaint) {
		return $self->{UNTAINT};
	}

	if(_is_yes($untaint)) {
		$self->{UNTAINT} = 1;
	}
	else {
		$self->{UNTAINT} = 0;
	}

}

sub _is_yes {
    return( defined($_[$[]) && ($_[$[] =~ /^[yYtT1]/));
}



#
# set default action.  Only if not already set
#
sub pointIn_default {
  my($action,$point,@points) = @_;

  $Action = $action if ($Action eq "");
  0;
}

#
# set default action if this point is the closest so far
# does not check for validity of parameters
#
sub pointIn_point {
  my($action,$point,$target) = @_;
  my($dist);
  my(@pt1);
  my(@pt2);

  @pt1 = $point =~ m/(\d+),(\d+)/;
  @pt2 = $target =~ m/(\d+),(\d+)/;

  $dist = ($pt1[0] - $pt2[0])**2 + ($pt1[1] - $pt2[1])**2;

  if ($minDistance == -1 || $dist < $minDistance) {
    $minDistance = $dist;
    $Action = $action;
  }
  0;
}

#
# if point is in given rectangle, set default action and cause main loop to end
#
sub pointIn_rect {
  my($action,$point,$target) = @_;
  my($ulx,$uly,$llx,$lly) = $target =~ m/(\d+),(\d+)\s+(\d+),(\d+)/;
  my($x,$y) = $point =~ m/(\d+),(\d+)/;

  if ($x >= $ulx && $y >= $uly && $x <= $llx && $y <= $lly) {
    $Action = $action;
    return 1;				# cause main loop to terminate
  }
  0;
}

#
# if point is in circle, set default action and cause main loop to end
#
sub pointIn_circle {
  my($action,$point,$target) = @_;
  my($cx,$cy,$ex,$ey) = $target =~ m/(\d+),(\d+)\s+(\d+),(\d+)/;
  my($x,$y) = $point =~ m/(\d+),(\d+)/;

  my($distanceP,$distanceE);

  # compare squares of distance from center of edgepoint and given point

  $distanceP = ($cx - $x)**2 + ($cy - $y)**2;
  $distanceE = ($cx - $ex)**2 + ($cy - $ey)**2;

  if ($distanceP <= $distanceE) {
    $Action = $action;
    return 1;				# cause main loop to terminate
  }
  0;
}

#
# if point is in given polygon, set default action and cause main loop to end
# based mostly on code by Mike Lyons <lyonsm@netbistro.com>.
#
sub pointIn_poly {
  my($action,$point,$target) = @_;
  my($x,$y) = $point =~ m/(\d+),(\d+)/;
  my($pn);
  my(@px);
  my(@py);
  my($i,$intersections,$dy,$dx,$b,$m,$x1,$y1,$x2,$y2);

  # We'll treat the test point as the origin, so translate each
  # point in the polygon appropriately
  while($target =~ s/\s*(\d+),(\d+)//) {
    $px[$pn] = $1 - $x;
    $py[$pn] = $2 - $y;
    $pn++;
  }

  # A polygon with less than 3 points is an error
  if($pn<3) {
    return 0;
  }

  # Close the polygon
  $px[$pn] = $px[0];
  $py[$pn] = $py[0];

  # Now count the number of line segments in the polygon that intersect
  # the left side of the X axis.  If it's an odd number we are inside the
  # polygon.

  # Assume no intersection
  $intersections=0;

  for($i = 0; $i < $pn; $i++) {
    $x1 = $px[$i  ]; $y1 = $py[$i  ];
    $x2 = $px[$i+1]; $y2 = $py[$i+1];

    # Line is completely to the right of the Y axis
    next if( ($x1>0) && ($x2>0) );

    # Line doesn't intersect the X axis at all
    next if( (($y1<=>0)==($y2<=>0)) && (($y1!=0)&&($y2!=0)) );

    # Special case.. if the Y on the bottom=0, we ignore this intersection
    # (otherwise a line endpoint counts as 2 hits instead of 1)
    if ($y2>$y1) {
      next if $y2==0;
    } elsif ($y1>$y2) {
      next if $y1==0;
    } else {
      # Horizontal span overlaying the X axis.  Consider it an intersection 
      # iff. it extends into the left side of the X axis
      $intersections++ if ( ($x1 < 0) || ($x2 < 0) );
      next;
    }

    # We know line must intersect the X axis, so see where
    $dx = $x2 - $x1;

    # Special case.. if a vertical line, it intersects
    unless ( $dx ) {
      $intersections++;
      next;
    }

    $dy = $y2 - $y1;
    $m = $dy / $dx;
    $b = $y2 - $m * $x2;
    next if ( ( (0 - $b) / $m ) > 0 );

    $intersections++;
  }

  # If there were an odd number of intersections to the left of the origin
  # (the clicked-on point) then it is within the polygon
  if ($intersections % 2) {
    $Action = $action;
    return 1;			# cause main loop to terminate
  }
  0;
}

1;

#!/usr/bin/perl -w
#
# $Id: test.pl,v 1.2 1996/03/02 06:27:51 mike Exp $
#
	use strict;
	use lib './blib/lib';
	use CGI::Imagemap qw(action_map map_untaint);
	my @map=( 
			"rect test1 148,0 223,20",
			"rect test2 231,0 289,20",
			"rect test3 296,0 346,20",
			"rect test4 354,0 422,20",
			"default default"
		);
	my %Errors;
	my $map = join "\0", @map;

	my $x = 323;
	my $y = 8;

	print "Testing static methods: ";
	fail("Static") if  map_untaint();
	map_untaint('yes');
	fail("Static") unless  map_untaint();
	map_untaint('no');
	fail("Static") if  map_untaint();
	fail("Static") unless  action_map($x,$y,@map) eq 'test3';
	fail("Static") unless  action_map($x,$y,$map) eq 'test3';
	print "OK\n" unless defined $Errors{'Static'};


	@map=( 
			"rect test1 148,0 223,20",
			"rect test2 231,0 289,20",
			"rect test4 354,0 422,20",
			"default default"
		);
	print "Testing class methods:  ";
	my $im = new CGI::Imagemap;
	fail("Class", 'untaint') if $im->untaint();
	$im->untaint('yes');
	fail("Class", 'untaint') unless $im->untaint();
	$im->setmap(@map);
	fail("Class", 'action') if $im->action($x,$y) ne 'default';
	$im->addmap("rect test3 296,0 346,20");
	fail("Class", 'addmap') if $im->action($x,$y) ne 'test3';
	$im->untaint('no');
	fail("Class", 'untaint') if $im->untaint();
	print "OK\n" unless defined $Errors{'Class'};

	my $status;
	unless (defined %Errors) {
		print "All tests passed.\n";
		$status = 0;
	}
	else {
		print "\n*** FAILED ***\n";
		$status = 1;
	}

	exit $status;


sub fail {

	my ($test, $subtest) = @_;
	print "$subtest FAILED\n"
		unless (defined  $Errors{$test} and $Errors{$test}++);

}



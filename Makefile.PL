# $Id: Makefile.PL,v 1.1 1996/03/02 06:44:04 mike Exp $
use ExtUtils::MakeMaker;
WriteMakefile(
        NAME        => 'CGI::Imagemap',
        VERSION     => '1.00',
        DISTNAME    => "CGI_Imagemap",
        dist        => {COMPRESS => 'gzip', SUFFIX => 'gz'},
        test        => {TEST_TYPE => './test.pl'},
);

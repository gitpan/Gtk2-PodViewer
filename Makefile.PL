#!/usr/bin/perl
# $Id: Makefile.PL,v 1.2 2003/09/09 16:45:03 jodrell Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Gtk2::PodViewer',
    'VERSION_FROM'	=> 'lib/Gtk2/PodViewer.pm',
    'PREREQ_PM'		=> {
    	Gtk2		=> 0,
    	Pod::Parser	=> 0,
    	IO::Scalar	=> 0,
    	File::Basename	=> 0,
    },
    'EXE_FILES'		=> [ 'src/podviewer' ]
);

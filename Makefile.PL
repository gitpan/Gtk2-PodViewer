#!/usr/bin/perl
# $Id: Makefile.PL,v 1.3 2003/09/14 16:36:26 jodrell Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Gtk2::PodViewer',
    'VERSION_FROM'	=> 'lib/Gtk2/PodViewer.pm',
    'PREREQ_FATAL'	=> 1,
    'PREREQ_PM'		=> {
    	Gtk2		=> 0,
    	Pod::Parser	=> 0,
    	IO::Scalar	=> 0,
    	File::Basename	=> 0,
    },
    'EXE_FILES'		=> [ 'src/podviewer' ]
);

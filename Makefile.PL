#!/usr/bin/perl
# $Id: Makefile.PL,v 1.5 2005/09/05 21:38:58 jodrell Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'			=> 'Gtk2::PodViewer',
    'VERSION_FROM'		=> 'lib/Gtk2/PodViewer.pm',
    'PREREQ_FATAL'		=> 1,
    'PREREQ_PM'			=> {
    	Gtk2			=> 0,
    	Pod::Parser		=> 0,
    	IO::Scalar		=> 0,
    	File::Basename		=> 0,
    	Locale::gettext		=> 0,
    	Pod::Simple::Search	=> 0,
    },
    'EXE_FILES'			=> [ 'src/podviewer' ]
);

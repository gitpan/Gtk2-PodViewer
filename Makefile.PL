#!/usr/bin/perl
# $Id: Makefile.PL,v 1.6 2005/10/04 11:18:04 jodrell Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'			=> 'Gtk2::PodViewer',
    'VERSION_FROM'		=> 'PodViewer.pm',
    'PREREQ_FATAL'		=> 1,
    'PREREQ_PM'			=> {
    	Gtk2::Ex::PodViewer	=> 0.13,
    },
);

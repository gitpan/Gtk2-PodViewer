# $Id: PodViewer.pm,v 1.23 2004/09/08 09:58:26 jodrell Exp $
# Copyright (c) 2003 Gavin Brown. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself. 
package Gtk2::PodViewer;
use Gtk2;
use Gtk2::PodViewer::Parser;
use vars qw($VERSION);
use Gtk2::Pango; # pango constants
use strict;

our $VERSION = '0.08a';

#
# we want to create a new signal for this object, which means we need to
# create a new GType.  however, using Glib::Object::Subclass (as of Glib
# 1.031 and all previous) makes it impossible for us to be require'd,
# thanks to the CHECK block madness.  so, we use Glib::Type::register
# directly.
#

# inherit new from Glib::Object.
*new = \&Glib::Object::new;

Glib::Type->register (
	Gtk2::TextView::,
	__PACKAGE__,
	signals => {
		link_clicked => {
			param_types => [qw/Glib::String/],
		},
		'link_enter' => {
			param_types => [qw/Glib::String/],
		},
		'link_leave' => {
			#param_types => [qw/Glib::String/],
		},
	},
);

sub INIT_INSTANCE {
	my $self = shift;
	$self->set_editable(0);
	$self->set_wrap_mode('word');
	$self->{parser} = Gtk2::PodViewer::Parser->new(buffer => $self->get_buffer);
	$self->get_buffer->create_tag(
		'bold',
		weight		=> PANGO_WEIGHT_BOLD
	);
	$self->get_buffer->create_tag(
		'italic',
		style		=> 'italic',
	);
	$self->get_buffer->create_tag(
		'word_wrap',
		wrap_mode	=> 'word',
	);
	$self->get_buffer->create_tag(
		'head1',
		weight		=> PANGO_WEIGHT_BOLD,
		size		=> 15 * PANGO_SCALE,
		wrap_mode	=> 'word',
	);
	$self->get_buffer->create_tag(
		'head2',
		weight		=> PANGO_WEIGHT_BOLD,
		size		=> 12 * PANGO_SCALE,
		wrap_mode	=> 'word',
	);
	$self->get_buffer->create_tag(
		'head3',
		weight		=> PANGO_WEIGHT_BOLD,
		size		=> 9 * PANGO_SCALE,
		wrap_mode	=> 'word',
	);
	$self->get_buffer->create_tag(
		'head4',
		weight		=> PANGO_WEIGHT_BOLD,
		size		=> 6 * PANGO_SCALE,
		wrap_mode	=> 'word',
	);
	$self->get_buffer->create_tag(
		'monospace',
		family		=> 'monospace',
		wrap_mode	=> 'none',
	);
	$self->get_buffer->create_tag(
		'typewriter',
		family		=> 'monospace',
		wrap_mode	=> 'word',
	);
	$self->get_buffer->create_tag(
		'link',
		foreground	=> 'blue',
		underline	=> 'single',
		wrap_mode	=> 'word',
	);
	$self->get_buffer->create_tag(
		'indented',
		left_margin	=> 40,
	);
	$self->get_buffer->create_tag(
		'normal',
		wrap_mode	=> 'word',
	);

	my $cursor	= Gtk2::Gdk::Cursor->new('xterm');
	my $url_cursor	= Gtk2::Gdk::Cursor->new('hand2');

	$self->signal_connect('button_release_event', sub { $self->clicked($_[1]) ; return 0 });

	$self->signal_connect_after('realize' => sub {
		my ($view) = @_;

		$view->get_window('text')->set_events([qw(exposure-mask
							  pointer-motion-mask
							  button-press-mask
							  button-release-mask
							  key-press-mask
							  structure-mask
							  property-change-mask
							  scroll-mask)]);

		return 0;
	});

	$self->signal_connect('motion_notify_event' => sub {
		my ($view, $event) = @_;
		my ($x, $y) = $view->window_to_buffer_coords('text', $event->x, $event->y);
		my $over_link = $view->get_iter_at_location($x, $y)->has_tag($view->get_buffer()->get_tag_table()->lookup("link"));
		if ($over_link == 1 && $self->{was_over_link} != 1) {
			# user has just brought the mouse over a link:
			$self->{was_over_link} = 1;
			my $text = $self->get_link_text_at_iter($view->get_iter_at_location($x, $y));
			$self->signal_emit('link_enter', $text) if ($text ne '');
		} elsif ($over_link != 1 && $self->{was_over_link} == 1) {
			# user has just the mouse away from a link:
			$self->{was_over_link} = 0;
			$self->signal_emit('link_leave');
		}

		$view->get_window('text')->set_cursor($over_link ? $url_cursor : $cursor);
		return 0;
	});
}
=pod

=head1 NAME

Gtk2::PodViewer - a Gtk2 widget for displaying Plain old Documentation (POD).

=head1 SYNOPSIS

	use Gtk2 -init;
	use Gtk2::PodViewer;

	my $viewer = Gtk2::PodViewer->new;

	$viewer->load('/path/to/file.pod');	# load a file
	$viewer->load('IO::Scalar');		# load a module
	$viewer->load('perlvar');		# load a perldoc
	$viewer->load('bless');			# load a function

	$viewer->show;				# see, it's a widget!

	my $window = Gtk2::Window->new;
	$window->add($viewer);

	$window->show;

	Gtk2->main;

=head1 DESCRIPTION

Gtk2::PodViewer is a widget for rendering Perl POD documents. It is based on the Gtk2::TextView widget and uses Pod::Parser for manipulating POD data.

Gtk2::PodViewer widgets inherit all the methods and properties of Gtk2::TextView widgets. Full information about text buffers can be found in the Gtk+ documentation at L<http://developer.gnome.org/doc/API/2.0/gtk/GtkTextView.html>.

=head1 OBJECT HIERARCHY

	L<Glib::Object>
	+--- L<Gtk2::Object>
	     +--- L<Gtk2::Widget>
	          +--- L<Gtk2::Editable>
		       +--- L<Gtk2::TextView>
			    +--- L<Gtk2::PodViewer>

=head1 CONSTRUCTOR

	my $view = Gtk2::PodViewer->new;

creates and returns a new Gtk2::PodViewer widget.


=head1 ADDITIONAL METHODS

	$viewer->clear;

This clears the viewer's buffer and resets the iter. You should never need to use this method since the loader methods (see L<Document Loaders> below) will do it for you.

=cut

sub clear {
	my $self = shift;
	$self->get_buffer->set_text('');
	$self->{parser}{iter} = $self->get_buffer->get_iter_at_offset(0);
	return 1;
}

=pod

	@marks = $view->get_marks;

This returns an array of section headers. So for example, a POD document of the form

	=pod

	=head1 NAME

	=head1 SYNOPSIS

	=cut

would result in

	@marks = ('NAME', 'SYNOPSIS');

You can then use the contents of this array to create a document index.

=cut

sub get_marks {
	return $_[0]->{parser}->get_marks;
}

=pod

	$name = 'SYNOPSIS';

	$mark = $view->get_mark($name);

returns the GtkTextMark object referred to by C<$name>.

=cut

sub get_mark {
	return $_[0]->{parser}->get_mark($_[1]);
}

=pod

	$name = 'SYNOPSIS';

	$view->jump_to($name);

this scrolls the PodViewer window to the selected mark.

=cut

sub jump_to {
	my ($self, $name) = @_;
	my $mark = $self->get_mark($name);
	return undef unless (ref($mark) eq 'Gtk2::TextMark');
	return $self->scroll_to_mark($mark, undef, 1, 0, 0);
}

=pod

	$viewer->load($document);

Loads a given document. C<$document> can be a perldoc name (eg., C<'perlvar'>), a module (eg. C<'IO::Scalar'>), a filename or the name of a Perl builtin function from L<perlfunc>. Documents are searched for in that order, that is, the L<perlvar> document will be loaded before a file called C<perlvar> in the current directory.

=cut

sub load {
	my ($self, $name) = @_;
	return 1 if $self->load_perldoc($name);
	return 1 if $self->load_module($name);
	return 1 if $self->load_file($name);
	return 1 if $self->load_function($name);
	return undef;
}

=pod

=head1 DOCUMENT LOADERS

The C<load()> method is a wrapper to a number of specialised document loaders. You can call one of these loaders directly to override the order in which Gtk2::PodViewer searches for documents:

	$viewer->load_perldoc($perldoc);

loads a perldoc file, or returns undef on failure.

	$viewer->load_module($module);

loads POD from a module file, or returns undef on failure.

	$viewer->load_file($file);

loads POD from a file, or returns undef on failure.

	$viewer->load_function($function);

This method scans the L<perlfunc> POD document for the documentation for a given function. The algorithm for this is lifted from the L<Pod::Perldoc> module, so it should work identically to C<perldoc -f [function]>.

	$viewer->load_string($string);

This method renders the POD data in the C<$string> variable.

=cut

sub load_perldoc {
	my ($self, $perldoc) = @_;
	foreach my $dir (@INC) {
		my $file = sprintf('%s/pod/%s.pod', $dir, $perldoc);
		if (-e $file) {
			$self->load_file($file);
			return 1;
		}
	}
	return undef;
}

sub load_module {
	my ($self, $module) = @_;
	$module =~ s!::!/!g;
	foreach my $dir (@INC) {
		my $pm_file  = sprintf('%s/%s.pm',  $dir, $module);
		my $pod_file = sprintf('%s/%s.pod', $dir, $module);
		if (-e $pod_file) {
			$self->load_file($pod_file);
			return 1;
		} elsif (-e $pm_file) {
			$self->load_file($pm_file);
			return 1;
		}
	}
	return undef;
}

sub load_function {
	my ($self, $function) = @_;
	my $perlfunc = $self->perlfunc;
	return undef if ($perlfunc eq '');
	open(PERLFUNC, $perlfunc) or return undef;
	# ignore everything up to here:
	while (<PERLFUNC>) {
		last if /^=head2 Alphabetical Listing of Perl Functions/;
	}
	# this is lifted straight from Pod/Perldoc.pm, with only a couple
	# of modifications:
	my $found = 0;
	my $inlist = 0;
	my $pod = '';
	while (<PERLFUNC>) {
		if (/^=item\s+\Q$function\E\b/)  {
			$found = 1;
		}
		elsif (/^=item/) {
			last if $found > 1 and not $inlist;
		}
		next unless $found;
		if (/^=over/) {
			++$inlist;
		}
		elsif (/^=back/) {
			--$inlist;
		}
		$pod .= $_;
		++$found if /^\w/;
	}
	close(PERLFUNC) or return undef;
	return undef if ($pod eq '');
	$self->load_string($pod);
	return 1;
}

sub load_file {
	my ($self, $file) = @_;
	if (-e $file) {
		$self->clear;
		$self->parser->clear_marks;
		$self->parser->parse_from_file($file);
		return 1;
	} else {
		return undef;
	}
}

sub load_string {
	my ($self, $string) = @_;
	$self->clear;
	$self->parser->clear_marks;
	$self->parser->parse_from_string($string);
	return 1;
}

sub perlfunc {
	my $self = shift;
	return $self->{perlfunc} if (defined($self->{perlfunc}));
	foreach my $dir (@INC) {
		my $file = sprintf('%s/pod/perlfunc.pod', $dir);
		if (-e $file) {
			$self->{perlfunc} = $file;
			return $self->{perlfunc};
		}
	}
}

=pod

	$parser = $view->parser;

returns the C<Gtk2::PodViewer::Parser> object used to render the POD data.

=cut

sub parser {
	return $_[0]->{parser};
}

sub clicked {
	my ($self, $event) = @_;
	my ($x, $y) = $self->window_to_buffer_coords('widget', $event->get_coords);
	my $iter = $self->get_iter_at_location($x, $y);
	my $text = $self->get_link_text_at_iter($iter);
	if ($text ne '') {
		$self->signal_emit('link_clicked', $text);
	}
	return 1;
}

sub get_link_text_at_iter {
	my ($self, $iter) = @_;
	my $tag = $self->get_buffer->get_tag_table->lookup('link');
	if ($iter->has_tag($tag)) {
		my $offset = $iter->get_offset;
		for (my $i = 0 ; $i < scalar(@{$self->parser->{links}}) ; $i++) {
			my ($text,  $this_offset) = @{@{$self->parser->{links}}[$i]};
			if ($offset >= $this_offset && $offset <= ($this_offset + length($text))) {
				return $text;
			}
		}
	}
	return undef;
}

=pod

=head1 SIGNALS

Gtk2::PodViewer inherits all of Gtk2::TextView's signals, and has the following:

=head2 The 'link_clicked' signal

	$viewer->signal_connect('link_clicked', \&clicked);

	sub clicked {
		my ($viewer, $link_text) = @_;
		print "user clicked on '$link_text'\n";
	}

Emitted when the user clicks on a hyperlink within the POD. This may be a section title, a document name, or a URL. The receiving function will be giving two arguments: a reference to the Gtk2::PodViewer object, and a scalar containing the link text.

=head2 The 'link_enter' signal

	$viewer->signal_connect('link_enter', \&enter);

	sub enter {
		my ($viewer, $link_text) = @_;
		print "user moused over '$link_text'\n";
	}

Emitted when the user moves the mouse pointer over a hyperlink within the POD. This may be a section title, a document name, or a URL. The receiving function will be giving two arguments: a reference to the Gtk2::PodViewer object, and a scalar containing the link text.

=head2 The 'link_leave' signal

	$viewer->signal_connect('link_leave', \&leave);

	sub clicked {
		my $viewer = shift;
		print "user moused out\n";
	}

Emitted when the user moves the mouse pointer out from a hyperlink within the POD. 

=head1 THE podviewer PROGRAM

C<podviewer> is installed with Gtk2::PodViewer. It is a simple Pod viewing program. It is pretty minimal, but does do the job quite well.

=head1 BUGS AND TASKS

Gtk2::PodViewer is a work in progress. All comments, complaints, offers of help and patches are welcomed.

We currently know about these issues:

=over

=item *

When rendering long documents the UI freezes for too long.

=item *

When you click on a link, the first line of text in the new document is hilighted.

=back

=head1 PREREQUISITES

=over

=item *

Gtk2 (obviously). The most recent version will be from L<http://gtk2-perl.sf.net/>.

=item *

Pod::Parser

=item *

IO::Scalar

=back

=head1 SEE ALSO

=over

=item *

L<Gtk2> or L<http://gtk2-perl.sf.net/>

=item *

L<http://developer.gnome.org/doc/API/2.0/gtk/GtkTextView.html>

=item *

L<Gtk2::PodViewer::Parser>

=back

=head1 AUTHORS

Gavin Brown, Torsten Schoenfeld and Scott Arrington.

=head1 COPYRIGHT

(c) 2004 Gavin Brown (gavin.brown@uk.com). All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut

1;

# $Id: Parser.pm,v 1.9 2003/09/12 16:11:11 jodrell Exp $
# Copyright (c) 2003 Gavin Brown. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself. package Gtk2::PodViewer::Parser;
package Gtk2::PodViewer::Parser;
use base 'Pod::Parser';
use IO::Scalar;
use strict;

=pod

=head1 NAME

Gtk2::PodViewer::Parser - a custom POD Parser for Gtk2::PodViewer.

=head1 SYNOPSIS

	my $parser = Gtk2::PodViewer::Parser->new(
		buffer	=> $Gtk2TextView->get_buffer,
	);

	$parser->parse_from_file($file);

=head1 DESCRIPTION

Gtk2::PodViewer::Parser is a custom Pod parser for the Gtk2::PodViewer widget. You should never need to use it directly.

It is based on L<Pod::Parser>.

=head1 METHODS

=cut

sub new {
	my $package = shift;
	my %args = @_;
	my $parser = $package->SUPER::new;
	$parser->{buffer} = $args{buffer};
	$parser->{iter} = $parser->{buffer}->get_iter_at_offset(0);
	bless($parser, $package);
	return $parser;
}

sub command {
	my ($parser, $command, $paragraph, $line_num) = @_;
	if ($command =~ /^head/i) {
		$paragraph =~ s/[\s\r\n]*$//g;
		my $mark = $parser->{buffer}->create_mark($paragraph, $parser->{iter}, 1);
		push(@{$parser->{marks}}, [$paragraph, $mark, $parser->{iter}]);
		$parser->insert_text($paragraph, $line_num, $command);
		$parser->insert_text("\n\n", $line_num);
	} elsif (lc($command) eq 'item') {
		my $dot = chr(183);
		$paragraph =~ s/\n*$//g;
		if ($paragraph eq '*') {
			$parser->insert_text("$dot ", $line_num, qw(word_wrap bold indented));
		} elsif ($paragraph =~ /^\*\s*/) {
			$paragraph =~ s/^\*\s*//;
			$parser->insert_text("$dot ", $line_num, qw(word_wrap bold indented));
			$parser->insert_text("$paragraph\n\n", $line_num, qw(word_wrap indented));
		} elsif ($paragraph =~ /^\d+$/i) {
			$parser->insert_text("$paragraph ", $line_num, qw(word_wrap bold indented));
		} else {
			$parser->insert_text("$dot ", $line_num, qw(word_wrap bold indented));
			$parser->insert_text("$paragraph\n\n", $line_num, qw(word_wrap indented));
		}
	} elsif ($command !~ /^(pod|cut|for|over|back)$/i) {
		warn("unknown command: $command on line $line_num");
		$parser->insert_text($paragraph, $line_num, qw(word_wrap));
	}
}

sub verbatim {
	my ($parser, $paragraph, $line_num) = @_;
	$parser->insert_text($paragraph, $line_num, qw(monospace));
}

sub textblock {
	my ($parser, $paragraph, $line_num) = @_;
	$paragraph =~ s/[\r\n]/ /sg;
	$paragraph .= "\n\n";
	$parser->insert_text($paragraph, $line_num, qw(word_wrap));
}

sub insert_text {
	my ($parser, $paragraph, $line_num, @tags) = @_;

	my %tagnames = (
		I	=> 'italic',
		B	=> 'bold',
		C	=> 'typewriter',
		L	=> 'link',
		F	=> 'italic',
		S	=> 'monospace',
		E	=> 'word_wrap',
	);
	my %entities = (
		lt	=> '<',
		gt	=> '>',
		verbar	=> '|',
		sol	=> '/',
	);

	$parser -> parse_text(
		{
			-expand_ptree => sub {
				my ($parser, $ptree) = @_;

				foreach ($ptree -> children()) {
					if (ref($_) eq "Pod::InteriorSequence") {
						my $sequence = $_;
						my $command = $sequence -> cmd_name();
						my $text = $sequence -> parse_tree() -> raw_text();

						if ($command eq 'E') {
							$text = $entities{$text} || $text;
						}

						$parser->{buffer}->insert_with_tags_by_name($parser->{iter}, $text, $tagnames{$command}, @tags);
					}
					else {
						my $text = $_;

						$parser->{buffer}->insert_with_tags_by_name($parser->{iter}, $text, @tags);
					}
				}
			}
		},
		$paragraph,
		$line_num
	);

	Gtk2->main_iteration while (Gtk2->events_pending);
	return 1;
}

sub clear_marks {
	$_[0]->{marks} = [];
	return 1;
}

sub get_marks {
	my @names;
	map { push(@names, @{$_}[0]) } @{$_[0]->{marks} };
	return @names;
}

sub get_mark {
	my ($parser, $name) = @_;
	foreach my $mark (@{$parser->{marks}}) {
		return @{$mark}[1] if (@{$mark}[0] eq $name);
	}
	return undef;
}

=pod

One neat method not implemented by Pod::Parser is

	$parser->parse_from_string($string);

This parses a scalar containing POD data, using IO::Scalar to create a tied filehandle.

=cut

sub parse_from_string {
	my ($self, $string) = @_;
	my $handle = IO::Scalar->new(\$string);
	$self->parse_from_filehandle($handle);
	$handle->close;
	return 1;
}

=pod

=head1 SEE ALSO

=over

=item *

L<Gtk2::PodViewer>

=item *

L<Pod::Parser>

=back

=head1 AUTHORS

Lead development by Gavin Brown.
Additional development by Torsten Schoenfeld.

=head1 COPYRIGHT

(c) 2003 Gavin Brown (gavin.brown@uk.com). All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut

1;

package Palette::Command::paint;
use Palette -command;
use strict;
use warnings;

# ABSTRACT: paint a file with a color

=head1 DESCRIPTION

Paint a target file using a chosen color and image format.

=cut

sub opt_spec {
  return (
    [ 'color=s',   'color to paint with',  { completion => 'fn:colors' } ],
    [ 'format=s',  'output image format',   { completion => [qw(png jpg svg pdf)] } ],
    [ 'output=s',  'destination file',      { completion => 'files' } ],
    [ 'verbose|v', 'show progress' ],
  );
}

sub execute {
  my ($self, $opt, $args) = @_;

  my $color  = $opt->color  // '(none)';
  my $format = $opt->format // '(none)';
  my $output = $opt->output // '(stdout)';

  print "Painting in $color as $format -> $output\n";
}

1;

package Palette::Command::show;
use Palette -command;
use strict;
use warnings;

# ABSTRACT: show information about a color

=head1 DESCRIPTION

Display information about a color, optionally searching a directory for
files that reference it.

=cut

sub opt_spec {
  return (
    [ 'color=s',      'color to look up',       { completion => 'fn:colors' } ],
    [ 'search-dir=s', 'directory to search in', { completion => 'dirs' } ],
    [ 'style=s',      'display style',           { completion => [qw(hex rgb name swatch)] } ],
  );
}

sub execute {
  my ($self, $opt, $args) = @_;

  my $color = $opt->color // '(none)';
  my $style = $opt->style // 'name';

  my %hex = (
    red    => 'FF0000', orange => 'FF7F00', yellow => 'FFFF00',
    green  => '00FF00', blue   => '0000FF', indigo => '4B0082',
    violet => 'EE82EE',
  );

  if ($style eq 'hex') {
    printf "#%s\n", $hex{$color} // '??????';
  } else {
    print "$color\n";
  }
}

1;

use strict;
use warnings;

package App::Cmd::Base::Elective;

# ABSTRACT: A Base class for App::Cmd that uses a whitelist instead of Module::Pluggable

use parent 'App::Cmd';

use Module::Runtime qw( compose_module_name module_notional_filename );
use Class::Load qw( load_optional_class );

=head1 SYNOPSIS

Preferred: 

    package Foo;
    use App::Cmd::Elective -app;
    sub app_commands { }

Which is similar, but not identical to

    package Foo;
    use App::Cmd::Base::Elective;
    use parent "App::Cmd::Base::Elective";

See L<App::Cmd::Tutorial> for more in depth usage. 

=cut

sub _expand_plugin_possible_names {
  my ( $self, $plugin_name ) = @_;
  return map { compose_module_name( $_, $plugin_name ) } @{ $self->plugin_search_path };
}

sub _expand_plugin_name {
  my ( $self, $plugin_name ) = @_;
  my (@candidates) = $self->_expand_plugin_possible_names($plugin_name);
  for my $candidate (@candidates) {
    return $candidate if load_optional_class($candidate);
  }
  my $message = 'Sorry, no plugin named <<' . $plugin_name . qq[>> could be found\n];
  $message .= qq[We tried the following expansions:\n];
  $message .= qq[\t$_\n] for @candidates;
  $message .= qq[\@INC contains:\n];
  $message .= qq[\t$_\n] for @INC;
  require Carp;
  Carp::croak($message);
}

my %plugins_for;

sub _plugins {
  my ($self) = @_;
  my $class = ref $self || $self;

  return @{ $plugins_for{$class} } if $plugins_for{$class};

  if ( not $class->can('app_commands') ) {
    require Carp;
    Carp::croak( 'Class <<' . $class . '>> lacks required method << app_commands >>' );
  }

  my @plugins;
  my (@search_path) = @{ $self->plugin_search_path };
  for my $plugin ( $self->app_commands ) {
    push @plugins, $self->_expand_plugin_name($plugin);
  }
  return @plugins;
}

1;

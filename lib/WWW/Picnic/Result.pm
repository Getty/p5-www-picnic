package WWW::Picnic::Result;
# ABSTRACT: Base class for Picnic API result objects
our $VERSION = '0.101';
use Moo;

=head1 SYNOPSIS

    # Base class for all result objects, not used directly
    package WWW::Picnic::Result::Something;
    use Moo;
    extends 'WWW::Picnic::Result';

=head1 DESCRIPTION

This is the base class for all WWW::Picnic result objects. It provides
common functionality for deserializing API responses into Perl objects.

=cut

has raw => (
  is => 'ro',
  required => 1,
);

=attr raw

The raw hashref data from the API response. Useful for accessing fields
that don't have dedicated accessors yet.

=cut

sub BUILDARGS {
  my ( $class, @args ) = @_;
  if ( @args == 1 && ref $args[0] ) {
    my $ref_type = ref $args[0];
    # Accept both HASH and ARRAY as raw data
    if ( $ref_type eq 'ARRAY' ) {
      return { raw => $args[0] };
    }
    if ( $ref_type eq 'HASH' && !exists $args[0]->{raw} ) {
      return { raw => $args[0] };
    }
  }
  return $class->SUPER::BUILDARGS(@args);
}

sub _get {
  my ( $self, $key ) = @_;
  return $self->raw->{$key};
}

1;

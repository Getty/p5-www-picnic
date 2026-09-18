package WWW::Picnic::Result::Suggestions;
# ABSTRACT: Collection of Picnic search suggestions
our $VERSION = '0.102';
use Moo;

extends 'WWW::Picnic::Result';

=head1 SYNOPSIS

    my $suggestions = $picnic->get_suggestions('har');
    say "Found ", $suggestions->total_count, " suggestions";

    for my $suggestion ($suggestions->all_suggestions) {
        say $suggestion->{suggestion};
    }

=head1 DESCRIPTION

Container for the search suggestions returned by the C<suggest> endpoint.
The API returns a plain list, reachable via L</all_suggestions>.

=cut

has suggestions => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my $self = shift;
    my $raw = $self->raw;
    return ref $raw eq 'ARRAY' ? $raw : ( $raw->{suggestions} || [] );
  },
);

=attr suggestions

Arrayref of suggestion entries from the API response.

=cut

sub all_suggestions {
  my ( $self ) = @_;
  return @{ $self->suggestions };
}

=method all_suggestions

Returns list of all suggestion entries (as opposed to arrayref).

=cut

sub total_count {
  my ( $self ) = @_;
  return scalar @{ $self->suggestions };
}

=method total_count

Returns total number of suggestions.

=cut

1;

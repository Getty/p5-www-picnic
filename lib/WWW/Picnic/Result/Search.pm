package WWW::Picnic::Result::Search;
# ABSTRACT: Picnic search results collection
our $VERSION = '0.101';
use Moo;

extends 'WWW::Picnic::Result';

use WWW::Picnic::Result::SearchResult;

=head1 SYNOPSIS

    my $search = $picnic->search('haribo');
    say "Found ", $search->total_count, " results";

    for my $item ($search->all_items) {
        say $item->name, " - ", $item->display_price;
    }

=head1 DESCRIPTION

Container for search results from the Picnic API. Extracts selling units
from the deeply nested response structure.

=cut

# Recursively find all sellingUnit objects in the response
sub _find_selling_units {
  my ($self, $data, $seen) = @_;
  $seen //= {};
  my @units;

  return @units unless ref $data;

  if (ref $data eq 'HASH') {
    # Found a sellingUnit
    if (exists $data->{sellingUnit} && ref $data->{sellingUnit} eq 'HASH') {
      my $unit = $data->{sellingUnit};
      my $id = $unit->{id};
      # Deduplicate by ID
      unless ($seen->{$id}++) {
        push @units, $unit;
      }
    }
    # Recurse into hash values
    for my $val (values %$data) {
      push @units, $self->_find_selling_units($val, $seen);
    }
  }
  elsif (ref $data eq 'ARRAY') {
    # Recurse into array elements
    for my $elem (@$data) {
      push @units, $self->_find_selling_units($elem, $seen);
    }
  }

  return @units;
}

has items => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my $self = shift;
    my @units = $self->_find_selling_units($self->raw);
    return [ map { WWW::Picnic::Result::SearchResult->new($_) } @units ];
  },
);

=attr items

Arrayref of L<WWW::Picnic::Result::SearchResult> objects extracted
from the search response.

=cut

sub all_items {
  my ( $self ) = @_;
  return @{ $self->items };
}

=method all_items

Returns list of all search result items.

=cut

sub total_count {
  my ( $self ) = @_;
  return scalar @{ $self->items };
}

=method total_count

Returns total number of items found.

=cut

sub first_group_id {
  my ( $self ) = @_;
  my $raw = $self->raw;
  # Try to extract from analytics context
  if (ref $raw eq 'HASH' && $raw->{body} && $raw->{body}{child}) {
    my $analytics = $raw->{body}{child}{analytics};
    if ($analytics && $analytics->{contexts}) {
      for my $ctx (@{$analytics->{contexts}}) {
        return $ctx->{data}{main_entity} if $ctx->{data} && $ctx->{data}{main_entity};
      }
    }
  }
  return;
}

=method first_group_id

Returns the main search entity (usually matches the search term).

=cut

1;

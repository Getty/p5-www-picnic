package WWW::Picnic::Result::SearchResult;
# ABSTRACT: Picnic product search result item

use Moo;

extends 'WWW::Picnic::Result';

=head1 SYNOPSIS

    my $results = $picnic->search('apple');
    for my $item ($results->all_items) {
        say $item->name;
        say "Price: ", $item->display_price;
    }

=head1 DESCRIPTION

Represents a single item from search results. Contains basic product
information suitable for display in search result lists.

=cut

has id => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('id') },
);

=attr id

Product identifier.

=cut

has name => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('name') },
);

=attr name

Product name.

=cut

has display_price => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('display_price') },
);

=attr display_price

Formatted price string for display.

=cut

has price => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('price') },
);

=attr price

Price in cents.

=cut

has image_id => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('image_id') },
);

=attr image_id

Identifier for the product image.

=cut

has unit_quantity => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('unit_quantity') },
);

=attr unit_quantity

Quantity/unit description (e.g., "500g", "1L").

=cut

has max_count => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('max_count') },
);

=attr max_count

Maximum quantity that can be ordered.

=cut

has decorators => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('decorators') || [] },
);

=attr decorators

Arrayref of decorators (badges, labels, etc.) for UI display.

=cut

1;

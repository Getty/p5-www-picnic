package WWW::Picnic::Result::Article;
# ABSTRACT: Detailed Picnic product/article information

use Moo;

extends 'WWW::Picnic::Result';

=head1 SYNOPSIS

    my $article = $picnic->get_article($product_id);
    say $article->name;
    say $article->description;
    say "Price: ", $article->price / 100, " EUR";

=head1 DESCRIPTION

Represents detailed product information including description,
nutritional info, allergens, and pricing details.

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

has description => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('description') },
);

=attr description

Full product description.

=cut

has type => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('type') },
);

=attr type

Product type.

=cut

has images => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('images') || [] },
);

=attr images

Arrayref of image identifiers.

=cut

has image_ids => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('image_ids') || [] },
);

=attr image_ids

Arrayref of image IDs.

=cut

has price_info => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('price_info') || {} },
);

=attr price_info

Hashref containing pricing details: C<price>, C<original_price>,
C<deposit>, C<base_price_text>.

=cut

sub price {
  my ( $self ) = @_;
  return $self->price_info->{price};
}

=method price

Returns the current price in cents.

=cut

sub original_price {
  my ( $self ) = @_;
  return $self->price_info->{original_price};
}

=method original_price

Returns the original price in cents (before discount).

=cut

sub deposit {
  my ( $self ) = @_;
  return $self->price_info->{deposit};
}

=method deposit

Returns deposit amount in cents, if any.

=cut

has unit_quantity => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('unit_quantity') },
);

=attr unit_quantity

Quantity/unit description (e.g., "500g", "1L").

=cut

has max_order_quantity => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('max_order_quantity') },
);

=attr max_order_quantity

Maximum quantity that can be ordered at once.

=cut

has labels => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('labels') || [] },
);

=attr labels

Arrayref of product labels (organic, vegan, etc.).

=cut

has allergies => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('allergies') || {} },
);

=attr allergies

Hashref containing allergy information: C<allergy_contains> (arrayref)
and C<allergy_text>.

=cut

has highlights => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('highlights') || [] },
);

=attr highlights

Arrayref of product highlights/features.

=cut

has perishable => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('perishable') },
);

=attr perishable

Boolean indicating if product is perishable.

=cut

1;

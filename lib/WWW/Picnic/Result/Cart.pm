package WWW::Picnic::Result::Cart;
# ABSTRACT: Picnic shopping cart / order
our $VERSION = '0.101';
use Moo;

extends 'WWW::Picnic::Result';

=head1 SYNOPSIS

    my $cart = $picnic->get_cart;
    say "Total: ", $cart->total_price / 100, " EUR";
    say "Items: ", $cart->total_count;

    for my $item (@{ $cart->items }) {
        say $item->{name}, " x ", $item->{count};
    }

=head1 DESCRIPTION

Represents a Picnic shopping cart (which is also an order). Contains
items, pricing, and delivery slot information.

=cut

has id => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('id') },
);

=attr id

Cart identifier, typically C<shopping_cart>.

=cut

has type => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('type') },
);

=attr type

Cart type, typically C<ORDER>.

=cut

has status => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('status') },
);

=attr status

Current status of the cart/order.

=cut

has items => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('items') || [] },
);

=attr items

Arrayref of order lines/items in the cart. Each item contains product
details, quantity, and pricing.

=cut

has total_count => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('total_count') || 0 },
);

=attr total_count

Total number of items in the cart.

=cut

has total_price => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('total_price') || 0 },
);

=attr total_price

Total price in cents. Divide by 100 to get the price in EUR.

=cut

has checkout_total_price => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('checkout_total_price') || 0 },
);

=attr checkout_total_price

Total price at checkout in cents, may include delivery fees.

=cut

has delivery_slots => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('delivery_slots') || [] },
);

=attr delivery_slots

Arrayref of available delivery slots for this cart.

=cut

has selected_slot => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('selected_slot') },
);

=attr selected_slot

Currently selected delivery slot, if any.

=cut

has deposit_breakdown => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('deposit_breakdown') || [] },
);

=attr deposit_breakdown

Arrayref of deposit charges (bottles, crates, etc.).

=cut

1;

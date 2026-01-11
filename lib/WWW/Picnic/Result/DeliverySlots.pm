package WWW::Picnic::Result::DeliverySlots;
# ABSTRACT: Collection of Picnic delivery slots
our $VERSION = '0.101';
use Moo;

extends 'WWW::Picnic::Result';

use WWW::Picnic::Result::DeliverySlot;

=head1 SYNOPSIS

    my $result = $picnic->get_delivery_slots;
    for my $slot ($result->all_slots) {
        next unless $slot->is_available;
        say $slot->window_start, " - ", $slot->window_end;
    }

=head1 DESCRIPTION

Container for delivery slot results from the API. Provides access to
the list of available delivery time slots.

=cut

has delivery_slots => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my $self = shift;
    my $slots = $self->_get('delivery_slots') || [];
    return [ map { WWW::Picnic::Result::DeliverySlot->new($_) } @$slots ];
  },
);

=attr delivery_slots

Arrayref of L<WWW::Picnic::Result::DeliverySlot> objects.

=cut

sub all_slots {
  my ( $self ) = @_;
  return @{ $self->delivery_slots };
}

=method all_slots

Returns list of all delivery slots (as opposed to arrayref).

=cut

sub available_slots {
  my ( $self ) = @_;
  return grep { $_->is_available } $self->all_slots;
}

=method available_slots

Returns list of only available delivery slots.

=cut

1;

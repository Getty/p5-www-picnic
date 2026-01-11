package WWW::Picnic::Result::DeliverySlot;
# ABSTRACT: Picnic delivery time slot

use Moo;

extends 'WWW::Picnic::Result';

=head1 SYNOPSIS

    my $slots = $picnic->get_delivery_slots;
    for my $slot (@{ $slots->delivery_slots }) {
        say $slot->window_start, " - ", $slot->window_end;
        say "Available: ", $slot->is_available ? "yes" : "no";
    }

=head1 DESCRIPTION

Represents an available delivery time slot with start/end times,
availability status, and minimum order requirements.

=cut

has slot_id => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('slot_id') },
);

=attr slot_id

Unique identifier for this delivery slot.

=cut

has hub_id => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('hub_id') },
);

=attr hub_id

Identifier of the delivery hub.

=cut

has fc_id => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('fc_id') },
);

=attr fc_id

Identifier of the fulfillment center.

=cut

has window_start => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('window_start') },
);

=attr window_start

Start time of the delivery window (ISO 8601 timestamp).

=cut

has window_end => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('window_end') },
);

=attr window_end

End time of the delivery window (ISO 8601 timestamp).

=cut

has cut_off_time => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('cut_off_time') },
);

=attr cut_off_time

Latest time to place an order for this slot (ISO 8601 timestamp).

=cut

has is_available => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('is_available') },
);

=attr is_available

Boolean indicating if this slot can be selected.

=cut

has unavailability_reason => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('unavailability_reason') },
);

=attr unavailability_reason

Reason why slot is unavailable, if C<is_available> is false.

=cut

has minimum_order_value => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('minimum_order_value') },
);

=attr minimum_order_value

Minimum order value in cents required for this slot.

=cut

1;

package WWW::Picnic::Result::User;
# ABSTRACT: Picnic user account information
our $VERSION = '0.101';
use Moo;

extends 'WWW::Picnic::Result';

=head1 SYNOPSIS

    my $user = $picnic->get_user;
    say $user->firstname, ' ', $user->lastname;
    say $user->contact_email;

=head1 DESCRIPTION

Represents a Picnic user account with profile information, address,
and account settings.

=cut

has user_id => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('user_id') },
);

=attr user_id

Unique identifier for the user account.

=cut

has firstname => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('firstname') },
);

=attr firstname

User's first name.

=cut

has lastname => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('lastname') },
);

=attr lastname

User's last name.

=cut

has contact_email => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('contact_email') },
);

=attr contact_email

Email address associated with the account.

=cut

has phone => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('phone') },
);

=attr phone

Phone number associated with the account.

=cut

has customer_type => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('customer_type') },
);

=attr customer_type

Type of customer account.

=cut

has address => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('address') },
);

=attr address

Hashref containing delivery address information with keys: C<street>,
C<house_number>, C<house_number_ext>, C<postcode>, C<city>.

=cut

has household_details => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('household_details') },
);

=attr household_details

Hashref containing household information.

=cut

has feature_toggles => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('feature_toggles') || [] },
);

=attr feature_toggles

Arrayref of enabled feature flags for this account.

=cut

has subscriptions => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('subscriptions') || [] },
);

=attr subscriptions

Arrayref of active subscriptions (e.g., Picnic Plus).

=cut

1;

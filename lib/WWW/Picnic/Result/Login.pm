package WWW::Picnic::Result::Login;
# ABSTRACT: Picnic login result with 2FA status

use Moo;

extends 'WWW::Picnic::Result';

=head1 SYNOPSIS

    my $login = $picnic->login;

    if ($login->requires_2fa) {
        $picnic->generate_2fa_code;
        print "Enter SMS code: ";
        my $code = <STDIN>;
        chomp $code;
        $picnic->verify_2fa_code($code);
    }

=head1 DESCRIPTION

Represents the result of a login attempt. Contains information about
whether two-factor authentication is required.

=cut

has auth_key => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('auth_key') },
);

=attr auth_key

The authentication token if login was successful.

=cut

has user_id => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('user_id') },
);

=attr user_id

The user ID from the login response.

=cut

has second_factor_authentication_required => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('second_factor_authentication_required') || 0 },
);

=attr second_factor_authentication_required

Boolean indicating if 2FA verification is required to complete login.

=cut

has show_second_factor_authentication_intro => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('show_second_factor_authentication_intro') || 0 },
);

=attr show_second_factor_authentication_intro

Boolean indicating if the 2FA intro should be shown to the user.

=cut

sub requires_2fa {
  my ( $self ) = @_;
  return $self->second_factor_authentication_required ? 1 : 0;
}

=method requires_2fa

Convenience method returning true if 2FA is required.

=cut

sub is_authenticated {
  my ( $self ) = @_;
  return $self->auth_key && !$self->requires_2fa ? 1 : 0;
}

=method is_authenticated

Returns true if fully authenticated (has auth key and no 2FA pending).

=cut

1;

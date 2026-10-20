package WWW::Picnic::Error;
# ABSTRACT: Exception object thrown for failed Picnic API calls
our $VERSION = '0.102';
use Moo;
use Carp qw( croak );
use namespace::clean;
# after namespace::clean on purpose: it would sweep the overload entries
use overload
  '""'     => sub { $_[0]->to_string },
  'bool'   => sub { 1 },
  fallback => 1;

=head1 SYNOPSIS

    use Scalar::Util qw( blessed );

    my $cart = eval { $picnic->get_cart };
    if ( my $err = $@ ) {
        if ( blessed $err && $err->isa('WWW::Picnic::Error') ) {
            warn $err->status;   # 404
            warn $err->method;   # GET
            warn $err->path;     # /api/15/cart
        }
        die $err;
    }

=head1 DESCRIPTION

Thrown by L<WWW::Picnic> whenever a call to the Picnic API fails: a non-2xx
response (a redirect among them) or a response body that is not valid JSON.

The object stringifies to the message the library croaks, so callers that
look at the string keep working. The string carries the status, the method
and the path of the failed call. It never carries the session token.

=cut

has message => (
  is => 'ro',
  default => sub { 'unknown error' },
);

=attr message

Human readable message: the HTTP status line of the failed call, or the
reason the answer could not be used.

=cut

has status => ( is => 'ro' );

=attr status

HTTP status code of the failed call, e.g. C<302>.

=cut

has method => ( is => 'ro' );

=attr method

HTTP method of the failed call, e.g. C<GET>.

=cut

has path => ( is => 'ro' );

=attr path

Path of the failed call, without host and scheme, with the query when the
call had one, e.g. C</api/15/pages/search-page-results?search_term=haribo>.

=cut

sub throw {
  my ( $class, %args ) = @_;
  croak $class->new(%args);
}

=method throw

    WWW::Picnic::Error->throw( message => '...', status => 404 );

Constructs the object and throws it.

=cut

sub to_string {
  my ( $self ) = @_;
  return defined $self->method && defined $self->path
    ? 'WWW::Picnic error ('.$self->method.' '.$self->path.'): '.$self->message
    : $self->message;
}

=method to_string

The string form: C<WWW::Picnic error (METHOD PATH): message>.

=cut

1;

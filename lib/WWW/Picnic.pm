package WWW::Picnic;
# ABSTRACT: Library to access Picnic Supermarket API
our $VERSION = '0.102';
use Moo;

use Carp qw( croak );
use JSON::MaybeXS;
use HTTP::Request;
use LWP::UserAgent;
use Digest::MD5 qw( md5_hex );
use URI::Escape;

use WWW::Picnic::Error;

use WWW::Picnic::Result::Login;
use WWW::Picnic::Result::User;
use WWW::Picnic::Result::Cart;
use WWW::Picnic::Result::DeliverySlots;
use WWW::Picnic::Result::Search;
use WWW::Picnic::Result::Article;
use WWW::Picnic::Result::Categories;
use WWW::Picnic::Result::Suggestions;

=head1 SYNOPSIS

    use WWW::Picnic;

    my $picnic = WWW::Picnic->new(
        user => 'user@universe.org',
        pass => 'alohahey',
        country => 'de',
    );

    # Explicit login with 2FA support
    my $login = $picnic->login;
    if ($login->requires_2fa) {
        $picnic->generate_2fa_code;
        print "Enter SMS code: ";
        my $code = <STDIN>;
        chomp $code;
        $picnic->verify_2fa_code($code);
    }

    # Search for products
    my $results = $picnic->search('apple');

    # Get your cart
    my $cart = $picnic->get_cart;

    # Get available delivery slots
    my $slots = $picnic->get_delivery_slots;

=head1 DESCRIPTION

B<WORK IN PROGRESS>

This module provides a Perl interface to the Picnic Supermarket API. It handles
authentication and provides methods to search for products, manage your cart,
and check delivery slots.

B<Note:> The results are objects: the methods return a
L<WWW::Picnic::Result::Search>, a L<WWW::Picnic::Result::Cart> and so on. The
raw answer of the API stays reachable with C<< $result->raw >>.

=cut

has user => (
  is => 'ro',
  required => 1,
);

=attr user

Login email address for your Picnic account. Required.

=cut

has pass => (
  is => 'ro',
  required => 1,
);

=attr pass

Password for your Picnic account. Required.

=cut

has client_id => (
  is => 'ro',
  default => sub { 30100 },
);

=attr client_id

Client identifier for API requests. Defaults to C<30100> (Android app).

=cut

has api_version => (
  isa => sub { $_[0] >= 15 },
  is => 'ro',
  default => sub { 15 },
);

=attr api_version

Picnic API version number. Must be 15 or higher. Defaults to C<15>.

=cut

has country => (
  is => 'ro',
  default => sub { 'de' },
);

=attr country

Two-letter country code for your Picnic account. Supported values are C<de> (Germany)
and C<nl> (Netherlands). Defaults to C<de>.

=cut

sub api_endpoint {
  my ( $self ) = @_;
  return sprintf('https://storefront-prod.%s.picnicinternational.com/api/%s', $self->country, "".$self->api_version."");
}

has http_agent => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my $self = shift;
    # No redirect is followed: a 3xx is an error, and the session token in
    # X-Picnic-Auth must not reach a foreign target.
    # The request does not hang for minutes, and the name of the host in the
    # certificate is checked whatever the environment says.
    my $ua = LWP::UserAgent->new(
      max_redirect => 0,
      timeout      => 30,
      ssl_opts     => { verify_hostname => 1 },
    );
    $ua->agent($self->http_agent_name);
    return $ua;
  },
);

=attr http_agent

L<LWP::UserAgent> instance used for making HTTP requests to the Picnic API.
Automatically created with the User-Agent string from L</http_agent_name>.
It does not follow redirects: a 3xx answer is an error, so the session
token never reaches a foreign target. A request times out after 30 seconds
and the name of the host in the certificate is checked.

=cut

has http_agent_name => (
  is => 'ro',
  lazy => 1,
  default => sub { 'okhttp/3.12.2' },
);

=attr http_agent_name

User-Agent string sent with HTTP requests. Defaults to C<okhttp/3.12.2> to mimic
the Picnic mobile app.

=cut

has picnic_agent => (
  is => 'ro',
  lazy => 1,
  default => sub { '30100;1.15.232-15154' },
);

=attr picnic_agent

Picnic agent identifier string. Defaults to Android app version.

=cut

has picnic_did => (
  is => 'ro',
  lazy => 1,
  default => sub {
    # Generate a random device ID (16 hex chars)
    my @chars = ('0'..'9', 'A'..'F');
    return join '', map { $chars[rand @chars] } 1..16;
  },
);

=attr picnic_did

Picnic device identifier. Auto-generated random hex string if not provided.

=cut

has json => (
  is => 'ro',
  lazy => 1,
  default => sub { return JSON::MaybeXS->new( utf8 => 1, convert_blessed => 1 ) },
);

has _auth_cache => (
  is => 'ro',
  default => sub {{}},
);

sub login {
  my ( $self ) = @_;
  my $url = URI->new(join('/',$self->api_endpoint,'user','login'));
  my $request = HTTP::Request->new( POST => $url );
  $request->header('Accept' => 'application/json');
  $request->header('Content-Type' => 'application/json; charset=UTF-8');
  $request->content($self->json->encode({
    key => $self->user,
    secret => md5_hex($self->pass),
    client_id => $self->client_id,
  }));
  my $response = $self->http_agent->request($request);
  unless ($response->is_success) {
    $self->_throw_http_error( $response, 'POST', $url );
  }
  my $auth = $response->header('X-Picnic-Auth');
  my $data = $self->_decode_json( $response, 'POST', $url );
  $data->{auth_key} = $auth;
  delete $self->_auth_cache->{pending};
  if ($auth && $data->{second_factor_authentication_required}) {
    $self->_auth_cache->{pending} = $auth;
  } elsif ($auth && $data->{user_id}) {
    $self->_auth_cache->{auth} = $auth;
    $self->_auth_cache->{user_id} = $data->{user_id};
  }
  return WWW::Picnic::Result::Login->new($data);
}

=method login

    my $login = $picnic->login;
    if ($login->requires_2fa) {
        # Handle 2FA
    }

Authenticates with the Picnic API. Returns a L<WWW::Picnic::Result::Login>
object that indicates whether two-factor authentication is required.

If 2FA is not required, the auth token is cached automatically. If 2FA is
required, the pending token from the response is kept separately and sent with
L</generate_2fa_code> and L</verify_2fa_code>.

A failed login throws a L<WWW::Picnic::Error> that names the status, the
method and the path of the failed call. An answer that is no JSON, and an
empty answer, are errors of the same kind.

=cut

sub generate_2fa_code {
  my ( $self, $channel ) = @_;
  $channel //= 'SMS';
  $self->_2fa_request( 'generate', { channel => $channel } );
  return 1;
}

sub _2fa_request {
  my ( $self, $step, $data ) = @_;
  my $pending = $self->_auth_cache->{pending};
  croak __PACKAGE__.": no pending 2FA login, call login() first" unless $pending;
  my $url = URI->new(join('/',$self->api_endpoint,'user','2fa',$step));
  my $request = HTTP::Request->new( POST => $url );
  $request->header('Accept' => 'application/json');
  $request->header('Content-Type' => 'application/json; charset=UTF-8');
  $request->header('X-Picnic-Auth' => $pending );
  $request->header('X-Picnic-Agent' => $self->picnic_agent );
  $request->header('X-Picnic-Did' => $self->picnic_did );
  $request->content($self->json->encode($data));
  my $response = $self->http_agent->request($request);
  unless ($response->is_success) {
    $self->_throw_http_error( $response, 'POST', $url );
  }
  return ( $response, $url );
}

=method generate_2fa_code

    $picnic->generate_2fa_code;
    $picnic->generate_2fa_code('SMS');  # explicit channel

Request a 2FA code to be sent via SMS (default) or another channel.
Call this after L</login> returns a result requiring 2FA.

A rejected request throws a L<WWW::Picnic::Error> that names the status, the
method and the path of the failed call.

=cut

sub verify_2fa_code {
  my ( $self, $code ) = @_;
  croak __PACKAGE__.": 2FA code required" unless defined $code;
  my ( $response, $url ) = $self->_2fa_request( 'verify', { otp => $code } );
  my $auth = $response->header('X-Picnic-Auth');
  croak __PACKAGE__.": 2FA verify success, but no auth token!" unless $auth;
  my $data = $self->_decode_json( $response, 'POST', $url, allow_empty => 1 );
  $data = {} unless ref $data eq 'HASH';
  $self->_auth_cache->{auth} = $auth;
  $self->_auth_cache->{user_id} = $data->{user_id} if $data->{user_id};
  delete $self->_auth_cache->{pending};
  return 1;
}

=method verify_2fa_code

    $picnic->verify_2fa_code('123456');

Verify the 2FA code received via SMS. On success, the auth token is
cached and you can proceed with API calls.

A rejected code throws a L<WWW::Picnic::Error> that names the status, the
method and the path of the failed call. An answer that is no JSON is an
error of the same kind, an empty answer is tolerated.

=cut

sub picnic_auth {
  my ( $self ) = @_;
  unless (defined $self->_auth_cache->{auth}) {
    my $login = $self->login;
    if ($login->requires_2fa) {
      croak __PACKAGE__.": 2FA required! Call login() and handle 2FA flow manually.";
    }
    unless ($self->_auth_cache->{auth}) {
      croak __PACKAGE__.": login failed to obtain auth token!";
    }
  }
  return $self->_auth_cache->{auth};
}

=method picnic_auth

    my $token = $picnic->picnic_auth;

Authenticates with the Picnic API using the provided L</user> and L</pass>.
Returns the authentication token (C<X-Picnic-Auth> header value). The token
is cached after the first successful authentication.

B<Note:> If 2FA is required, this method will croak. Use L</login> instead
and handle the 2FA flow manually.

This method is called automatically by L</request>, so you typically don't
need to call it directly.

=cut

# The path of a failed call: without host and scheme, with the query when the
# call had one. The session token never appears here.
sub _error_path {
  my ( $self, $url ) = @_;
  my $path = $url->path;
  $path .= '?'.$url->query if $url->query;
  return $path;
}

sub _throw_error {
  my ( $self, $response, $method, $url, $message ) = @_;
  WWW::Picnic::Error->throw(
    message => $message,
    status  => $response->code,
    method  => $method,
    path    => $self->_error_path($url),
  );
}

sub _throw_http_error {
  my ( $self, $response, $method, $url ) = @_;
  $self->_throw_error( $response, $method, $url, $response->status_line );
}

# The JSON of an answer: an empty body and a body that is no JSON are errors.
# A failure later would name the wrong cause.
sub _decode_json {
  my ( $self, $response, $method, $url, %opt ) = @_;
  my $content = $response->content;
  if ( !defined $content or !length $content ) {
    return {} if $opt{allow_empty};
    $self->_throw_error( $response, $method, $url, 'HTTP '.$response->code.': the answer was empty' );
  }
  my $data = eval { $self->json->decode($content) };
  if ( $@ ) {
    $self->_throw_error( $response, $method, $url, 'HTTP '.$response->code.': the answer was no JSON' );
  }
  return $data;
}

sub request {
  my ( $self, @original_args ) = @_;
  my ( $method, $path, $data, %params ) = @original_args;
  $data = [] if $method eq 'PUT' and !$data;
  my $url = URI->new(join('/',$self->api_endpoint,$path));
  if (%params) {
    $url->query_form(%params);
  }
  my $response;
  for my $attempt ( 1, 2 ) {
    my $request = HTTP::Request->new( $method => $url );
    $request->header('Accept' => 'application/json');
    $request->header('X-Picnic-Auth' => $self->picnic_auth );
    $request->header('X-Picnic-Agent' => $self->picnic_agent );
    $request->header('X-Picnic-Did' => $self->picnic_did );
    if (defined $data) {
      $request->header('Content-Type' => 'application/json');
      $request->content($self->json->encode($data));
    }
    $response = $self->http_agent->request($request);
    last unless $response->code == 401 and $attempt == 1;
    # Expired or revoked token: drop it, picnic_auth logs in again, retry once
    delete @{$self->_auth_cache}{qw( auth user_id pending )};
  }
  unless ($response->is_success) {
    $self->_throw_http_error( $response, $method, $url );
  }
  return $self->_decode_json( $response, $method, $url );
}

=method request

    my $result = $picnic->request($method, $path, $data, %params);

Makes an authenticated HTTP request to the Picnic API. Returns the decoded JSON response.

Parameters:

=over 4

=item * C<$method> - HTTP method (GET, POST, PUT, etc.)

=item * C<$path> - API endpoint path (relative to api_endpoint)

=item * C<$data> - Optional hashref/arrayref to send as JSON body

=item * C<%params> - Optional query parameters

=back

If the API answers with C<401> (expired or revoked token), the cached
authentication is discarded, L</picnic_auth> logs in again (croaking as usual
if 2FA is required) and the call is repeated exactly once. A second C<401>, or
any other non-2xx status, throws a L<WWW::Picnic::Error> that names the
status, the method and the path of the failed call.

The answer must be JSON: an empty body and a body that is no JSON throw a
L<WWW::Picnic::Error> that names the status, the method and the path of the
failed call.

This is a low-level method used internally by other methods. You typically won't
need to call it directly unless accessing undocumented API endpoints.

=cut

sub get_user {
  my ( $self ) = @_;
  return WWW::Picnic::Result::User->new( $self->request( GET => 'user' ) );
}

=method get_user

    my $user = $picnic->get_user;
    say $user->firstname, " ", $user->lastname;

Returns a L<WWW::Picnic::Result::User> object with your account details.

=cut

sub get_cart {
  my ( $self ) = @_;
  return WWW::Picnic::Result::Cart->new( $self->request( GET => 'cart' ) );
}

=method get_cart

    my $cart = $picnic->get_cart;
    say "Items: ", $cart->total_count;
    say "Total: ", $cart->total_price / 100, " EUR";

Returns a L<WWW::Picnic::Result::Cart> object with your shopping cart contents.

=cut

sub clear_cart {
  my ( $self ) = @_;
  return WWW::Picnic::Result::Cart->new( $self->request( POST => 'cart/clear' ) );
}

=method clear_cart

    my $cart = $picnic->clear_cart;

Removes all items from your shopping cart. Returns the updated
L<WWW::Picnic::Result::Cart> object.

=cut

sub get_delivery_slots {
  my ( $self ) = @_;
  return WWW::Picnic::Result::DeliverySlots->new( $self->request( GET => 'cart/delivery_slots' ) );
}

=method get_delivery_slots

    my $slots = $picnic->get_delivery_slots;
    for my $slot ($slots->available_slots) {
        say $slot->window_start, " - ", $slot->window_end;
    }

Returns a L<WWW::Picnic::Result::DeliverySlots> object with available
delivery time slots for your current cart.

=cut

sub search {
  my ( $self, $term ) = @_;
  $self->_require_argument( 'search', 'term', $term );
  return WWW::Picnic::Result::Search->new( $self->request( GET => 'pages/search-page-results', undef, search_term => $term ) );
}

=method search

    my $results = $picnic->search('haribo');
    for my $item ($results->all_items) {
        say $item->name, " - ", $item->display_price;
    }

Search for products by name or term. Returns a L<WWW::Picnic::Result::Search>
object containing the results.

Croaks when the search term is missing or empty.

=cut

# The argument of a method that goes to the API: it must be there. A clear
# message beats the answer of the API.
sub _require_argument {
  my ( $self, $method, $name, $value ) = @_;
  croak $method.": ".$name." is required" unless defined $value;
  croak $method.": ".$name." must not be empty" unless length $value;
  return $value;
}

# The one place a caller-supplied value becomes part of a request path: the
# value must stay one segment whatever it holds.
sub _path_segment {
  my ( $self, $name, $value ) = @_;
  # No encoding helps for these: '' removes the segment, and '.' / '..' are
  # dot segments to every URL normaliser even when written as %2E.
  croak __PACKAGE__.": path parameter '$name' cannot be empty, '.' or '..'"
    if !defined $value or $value eq '' or $value eq '.' or $value eq '..';
  return uri_escape_utf8($value);
}

sub get_article {
  my ( $self, $product_id ) = @_;
  $self->_require_argument( 'get_article', 'product_id', $product_id );
  my $segment = $self->_path_segment( 'product_id', $product_id );
  return WWW::Picnic::Result::Article->new( $self->request( GET => 'articles/'.$segment ) );
}

=method get_article

    my $article = $picnic->get_article($product_id);
    say $article->name;
    say $article->description;

Get detailed information about a specific product. Returns a
L<WWW::Picnic::Result::Article> object.

The product id is sent as one path segment: it is escaped, and the values
C<''>, C<.> and C<..> are refused.

Croaks when the product id is missing or empty.

=cut

sub add_to_cart {
  my ( $self, $product_id, $count ) = @_;
  $self->_require_argument( 'add_to_cart', 'product_id', $product_id );
  $count //= 1;
  return WWW::Picnic::Result::Cart->new(
    $self->request( POST => 'cart/add_product', { product_id => $product_id, count => $count } )
  );
}

=method add_to_cart

    my $cart = $picnic->add_to_cart($product_id);
    my $cart = $picnic->add_to_cart($product_id, 3);  # add 3 items

Add a product to your shopping cart. Optionally specify quantity (default: 1).
Returns the updated L<WWW::Picnic::Result::Cart> object.

Croaks when the product id is missing or empty.

=cut

sub remove_from_cart {
  my ( $self, $product_id, $count ) = @_;
  $self->_require_argument( 'remove_from_cart', 'product_id', $product_id );
  $count //= 1;
  return WWW::Picnic::Result::Cart->new(
    $self->request( POST => 'cart/remove_product', { product_id => $product_id, count => $count } )
  );
}

=method remove_from_cart

    my $cart = $picnic->remove_from_cart($product_id);
    my $cart = $picnic->remove_from_cart($product_id, 2);  # remove 2 items

Remove a product from your shopping cart. Optionally specify quantity (default: 1).
Returns the updated L<WWW::Picnic::Result::Cart> object.

Croaks when the product id is missing or empty.

=cut

sub set_delivery_slot {
  my ( $self, $slot_id ) = @_;
  $self->_require_argument( 'set_delivery_slot', 'slot_id', $slot_id );
  return WWW::Picnic::Result::Cart->new(
    $self->request( POST => 'cart/set_delivery_slot', { slot_id => $slot_id } )
  );
}

=method set_delivery_slot

    my $cart = $picnic->set_delivery_slot($slot_id);

Select a delivery slot for your order. Returns the updated
L<WWW::Picnic::Result::Cart> object.

Croaks when the slot id is missing or empty.

=cut

sub get_categories {
  my ( $self, $depth ) = @_;
  $depth //= 0;
  return WWW::Picnic::Result::Categories->new( $self->request( GET => 'my_store', undef, depth => $depth ) );
}

=method get_categories

    my $categories = $picnic->get_categories;
    my $categories = $picnic->get_categories(2);  # with depth

Get product categories. Optionally specify depth for nested categories.
Returns a L<WWW::Picnic::Result::Categories> object.

=cut

sub get_suggestions {
  my ( $self, $term ) = @_;
  return WWW::Picnic::Result::Suggestions->new( $self->request( GET => 'suggest', undef, search_term => $term ) );
}

=method get_suggestions

    my $suggestions = $picnic->get_suggestions('app');

Get search suggestions for a partial search term. Returns a
L<WWW::Picnic::Result::Suggestions> object.

=cut

1;

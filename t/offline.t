#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use lib 't/lib';
use Scalar::Util qw( blessed );

BEGIN {
  use_ok('WWW::Picnic');
  use_ok('WWW::Picnic::MockUA');
  use_ok('WWW::Picnic::Result::Login');
  use_ok('WWW::Picnic::Result::User');
  use_ok('WWW::Picnic::Result::Cart');
  use_ok('WWW::Picnic::Result::DeliverySlots');
  use_ok('WWW::Picnic::Result::DeliverySlot');
  use_ok('WWW::Picnic::Result::Search');
  use_ok('WWW::Picnic::Result::SearchResult');
  use_ok('WWW::Picnic::Result::Article');
}

my $fake_user = 'test@example.com';
my $fake_pass = 'testpassword';
my $fake_country = 'de';

# Create mock UA with responses
my $mock_ua = WWW::Picnic::MockUA->new;
$mock_ua->add_response(
  'user/login',
  WWW::Picnic::MockUA::sample_login_response(),
  headers => { 'X-Picnic-Auth' => 'mock-auth-token-12345' },
);
$mock_ua->add_response('api/\d+/user$', WWW::Picnic::MockUA::sample_user_response());
$mock_ua->add_response('cart$', WWW::Picnic::MockUA::sample_cart_response());
$mock_ua->add_response('cart/clear', WWW::Picnic::MockUA::sample_cart_response());
$mock_ua->add_response('cart/delivery_slots', WWW::Picnic::MockUA::sample_delivery_slots_response());
$mock_ua->add_response('search-page-results', WWW::Picnic::MockUA::sample_search_response());
$mock_ua->add_response('articles/', WWW::Picnic::MockUA::sample_article_response());
$mock_ua->add_response('cart/add_product', WWW::Picnic::MockUA::sample_cart_response());
$mock_ua->add_response('cart/remove_product', WWW::Picnic::MockUA::sample_cart_response());
$mock_ua->add_response('cart/set_delivery_slot', WWW::Picnic::MockUA::sample_cart_response());
$mock_ua->add_response('my_store', WWW::Picnic::MockUA::sample_categories_response());
$mock_ua->add_response('suggest', WWW::Picnic::MockUA::sample_suggestions_response());

my $picnic = WWW::Picnic->new(
  user       => $fake_user,
  pass       => $fake_pass,
  country    => $fake_country,
  http_agent => $mock_ua,
);

subtest 'Basic attributes' => sub {
  isa_ok($picnic, 'WWW::Picnic');
  is($picnic->user, $fake_user, "User is set");
  is($picnic->pass, $fake_pass, "Pass is set");
  is($picnic->country, $fake_country, "Country is set");
  is($picnic->api_version, 15, "Default API version is 15");
  like($picnic->api_endpoint, qr/storefront-prod\.de\.picnicinternational\.com/, "API endpoint is correct");
};

subtest 'Login' => sub {
  my $login = $picnic->login;
  isa_ok($login, 'WWW::Picnic::Result::Login');
  is($login->user_id, 'test-user-123', 'Login user_id');
  ok(!$login->requires_2fa, 'No 2FA required');
  ok($login->is_authenticated, 'Is authenticated');
};

subtest 'User' => sub {
  my $user = $picnic->get_user;
  isa_ok($user, 'WWW::Picnic::Result::User');
  is($user->user_id, 'test-user-123', 'User ID');
  is($user->firstname, 'Max', 'First name');
  is($user->lastname, 'Mustermann', 'Last name');
  is($user->contact_email, 'max@example.com', 'Email');
  is($user->phone, '+49123456789', 'Phone');
  is($user->customer_type, 'REGULAR', 'Customer type');
  is_deeply($user->address, {
    street           => 'Musterstraße',
    house_number     => '42',
    house_number_ext => 'a',
    postcode         => '12345',
    city             => 'Berlin',
  }, 'Address');
  is_deeply($user->feature_toggles, ['feature_a', 'feature_b'], 'Feature toggles');
};

subtest 'Cart' => sub {
  my $cart = $picnic->get_cart;
  isa_ok($cart, 'WWW::Picnic::Result::Cart');
  is($cart->id, 'shopping_cart', 'Cart ID');
  is($cart->type, 'ORDER', 'Cart type');
  is($cart->status, 'OPEN', 'Cart status');
  is($cart->total_count, 3, 'Total count');
  is($cart->total_price, 377, 'Total price');
  is(scalar @{$cart->items}, 2, 'Number of items');
  is($cart->items->[0]{name}, 'Haribo Goldbären', 'First item name');
};

subtest 'Clear cart' => sub {
  my $cart = $picnic->clear_cart;
  isa_ok($cart, 'WWW::Picnic::Result::Cart');
};

subtest 'Delivery slots' => sub {
  my $slots = $picnic->get_delivery_slots;
  isa_ok($slots, 'WWW::Picnic::Result::DeliverySlots');
  is(scalar $slots->all_slots, 2, 'Total slots');
  is(scalar $slots->available_slots, 1, 'Available slots');

  my ($available) = $slots->available_slots;
  isa_ok($available, 'WWW::Picnic::Result::DeliverySlot');
  is($available->slot_id, 'slot-1', 'Slot ID');
  is($available->hub_id, 'hub-berlin-1', 'Hub ID');
  ok($available->is_available, 'Is available');
  is($available->window_start, '2025-01-15T10:00:00Z', 'Window start');
  is($available->window_end, '2025-01-15T12:00:00Z', 'Window end');
};

subtest 'Search' => sub {
  my $search = $picnic->search('haribo');
  isa_ok($search, 'WWW::Picnic::Result::Search');
  is($search->total_count, 2, 'Total results');
  is($search->first_group_id, 'haribo', 'First group ID');

  my @items = $search->all_items;
  is(scalar @items, 2, 'Number of items');
  isa_ok($items[0], 'WWW::Picnic::Result::SearchResult');
  is($items[0]->id, 'product-1', 'First item ID');
  is($items[0]->name, 'Haribo Goldbären 200g', 'First item name');
  is($items[0]->display_price, 129, 'Display price in cents');
  is($items[0]->unit_quantity, '200g', 'Unit quantity');
};

subtest 'Article' => sub {
  my $article = $picnic->get_article('product-1');
  isa_ok($article, 'WWW::Picnic::Result::Article');
  is($article->id, 'product-1', 'Article ID');
  is($article->name, 'Haribo Goldbären 200g', 'Article name');
  like($article->description, qr/Gummibärchen/, 'Description');
  is($article->price, 129, 'Price');
  is($article->original_price, 149, 'Original price');
  is($article->deposit, 0, 'Deposit');
  is($article->unit_quantity, '200g', 'Unit quantity');
  is($article->max_order_quantity, 10, 'Max order quantity');
  ok(!$article->perishable, 'Not perishable');
  is_deeply($article->labels, ['vegetarian'], 'Labels');
};

subtest 'Add to cart' => sub {
  my $cart = $picnic->add_to_cart('product-1', 2);
  isa_ok($cart, 'WWW::Picnic::Result::Cart');
};

subtest 'Remove from cart' => sub {
  my $cart = $picnic->remove_from_cart('product-1', 1);
  isa_ok($cart, 'WWW::Picnic::Result::Cart');
};

subtest 'Set delivery slot' => sub {
  my $cart = $picnic->set_delivery_slot('slot-1');
  isa_ok($cart, 'WWW::Picnic::Result::Cart');
  is($cart->id, 'shopping_cart', 'Cart ID');
  is($cart->total_count, 3, 'Total count');
};

subtest 'Categories' => sub {
  my $cats = $picnic->get_categories;
  isa_ok($cats, 'WWW::Picnic::Result::Categories');
  is($cats->total_count, 2, 'Number of categories');
  is(scalar $cats->all_categories, 2, 'all_categories list');
  is($cats->catalog->[0]{id}, 'cat-1', 'First category ID');
  is($cats->catalog->[0]{name}, 'Obst & Gemüse', 'First category name');
};

subtest 'Suggestions' => sub {
  my $suggestions = $picnic->get_suggestions('har');
  isa_ok($suggestions, 'WWW::Picnic::Result::Suggestions');
  is($suggestions->total_count, 2, 'Number of suggestions');
  is(scalar $suggestions->all_suggestions, 2, 'all_suggestions list');
  is($suggestions->suggestions->[0]{suggestion}, 'haribo', 'First suggestion text');
};

subtest 'Result raw access' => sub {
  my $user = $picnic->get_user;
  ok($user->can('raw'), 'Has raw method');
  is(ref $user->raw, 'HASH', 'Raw is hashref');
  is($user->raw->{firstname}, 'Max', 'Can access raw data');
};

subtest '2FA flow sends pending token and device headers' => sub {
  my $ua = WWW::Picnic::MockUA->new;
  $ua->add_response('user/login', WWW::Picnic::MockUA::sample_login_2fa_response(),
    headers => { 'X-Picnic-Auth' => 'pending-token' });
  $ua->add_response('user/2fa/generate', {});
  $ua->add_response('user/2fa/verify', undef, raw => '',
    headers => { 'X-Picnic-Auth' => 'final-token' });
  $ua->add_response('api/\d+/user$', WWW::Picnic::MockUA::sample_user_response());
  my $p = WWW::Picnic->new(
    user => $fake_user, pass => $fake_pass, country => $fake_country, http_agent => $ua,
  );

  my $login = $p->login;
  ok($login->requires_2fa, 'login requires 2FA');
  ok(!$p->_auth_cache->{auth}, 'pending token is not a full login');
  is($p->_auth_cache->{pending}, 'pending-token', 'pending token kept');

  ok($p->generate_2fa_code, 'generate_2fa_code');
  ok($p->verify_2fa_code('123456'), 'verify_2fa_code tolerates empty body');

  my ( $l, $gen, $ver ) = $ua->all_requests;
  for my $r ( $gen, $ver ) {
    is($r->header('X-Picnic-Auth'), 'pending-token', $r->uri->path.': pending token sent');
    is($r->header('X-Picnic-Agent'), $p->picnic_agent, $r->uri->path.': agent sent');
    is($r->header('X-Picnic-Did'), $p->picnic_did, $r->uri->path.': did sent');
  }
  like($gen->content, qr/"channel"\s*:\s*"SMS"/, 'generate body');
  like($ver->content, qr/"otp"\s*:\s*"123456"/, 'verify body');

  is($p->picnic_auth, 'final-token', 'final token cached');
  ok(!exists $p->_auth_cache->{pending}, 'pending cleared after verify');
  $p->get_user;
  is(($ua->all_requests)[-1]->header('X-Picnic-Auth'), 'final-token', 'later requests use final token');
};

{
  package SeqUA;
  our @ISA = ('WWW::Picnic::MockUA');
  # answers the first $n calls to api/.../user with 401
  sub request {
    my ( $self, $req ) = @_;
    my $res = $self->SUPER::request($req);
    if ( $req->uri->path =~ m{/user$} and $self->{fail}-- > 0 ) {
      $res->code(401);
    }
    return $res;
  }
}

subtest '401 triggers one re-login and retry' => sub {
  my $ua = SeqUA->new( fail => 1 );
  $ua->add_response('user/login', WWW::Picnic::MockUA::sample_login_response(),
    headers => { 'X-Picnic-Auth' => 'tok' });
  $ua->add_response('api/\d+/user$', WWW::Picnic::MockUA::sample_user_response());
  my $p = WWW::Picnic->new(
    user => $fake_user, pass => $fake_pass, country => $fake_country, http_agent => $ua,
  );
  ok($p->get_user, 'call succeeds after re-login');
  my @paths = map { $_->uri->path } $ua->all_requests;
  is(scalar(grep { m{user/login$} } @paths), 2, 'logged in twice');
  is(scalar(grep { m{/user$} } @paths), 2, 'call made twice');
};

subtest 'second 401 croaks without looping' => sub {
  my $ua = SeqUA->new( fail => 100 );
  $ua->add_response('user/login', WWW::Picnic::MockUA::sample_login_response(),
    headers => { 'X-Picnic-Auth' => 'tok' });
  $ua->add_response('api/\d+/user$', WWW::Picnic::MockUA::sample_user_response());
  my $p = WWW::Picnic->new(
    user => $fake_user, pass => $fake_pass, country => $fake_country, http_agent => $ua,
  );
  eval { $p->get_user };
  like($@, qr/401/, 'croaks on repeated 401');
  is(scalar(grep { $_->uri->path =~ m{/user$} } $ua->all_requests), 2, 'exactly one retry');
};

# The attributes of a thrown error, or undef when the call threw no
# WWW::Picnic::Error. Keeps a failing expectation from dying.
sub error_attributes {
  my ( $err ) = @_;
  return undef unless blessed($err) && $err->isa('WWW::Picnic::Error');
  return {
    status  => $err->status,
    method  => $err->method,
    path    => $err->path,
    message => $err->message,
  };
}

subtest 'the user agent does not follow a redirect' => sub {
  my $p = WWW::Picnic->new(
    user => $fake_user, pass => $fake_pass, country => $fake_country,
  );
  is( $p->http_agent->max_redirect, 0, 'no redirect is followed' );
};

subtest 'the request times out and the host in the certificate is checked' => sub {
  my $p = WWW::Picnic->new(
    user => $fake_user, pass => $fake_pass, country => $fake_country,
  );
  my $ua = $p->http_agent;
  is( $ua->timeout, 30, 'the request does not hang for minutes' );
  is( $ua->ssl_opts('verify_hostname'), 1, 'the name of the host is checked' );
};

subtest 'a redirect is an error that names status, method and path' => sub {
  my $ua = WWW::Picnic::MockUA->new;
  $ua->add_response('user/login', WWW::Picnic::MockUA::sample_login_response(),
    headers => { 'X-Picnic-Auth' => 'mock-auth-token-12345' });
  $ua->add_response('cart$', undef, status => 302, raw => 'moved');
  my $p = WWW::Picnic->new(
    user => $fake_user, pass => $fake_pass, country => $fake_country, http_agent => $ua,
  );

  my $err = do { eval { $p->get_cart }; $@ };
  ok( blessed($err), 'the failed call throws an object' );
  is( ref $err, 'WWW::Picnic::Error', 'the object is a WWW::Picnic::Error' );
  like( "$err", qr{^WWW::Picnic error \(GET /api/15/cart\): 302 Found$},
    'the message names the status, the method and the path' );
  unlike( "$err", qr/mock-auth-token-12345/, 'the message carries no session token' );

  my $attributes = error_attributes($err);
  SKIP: {
    skip 'no WWW::Picnic::Error to look at', 4 unless $attributes;
    is( $attributes->{status}, 302, 'status' );
    is( $attributes->{method}, 'GET', 'method' );
    is( $attributes->{path}, '/api/15/cart', 'path' );
    is( $attributes->{message}, '302 Found', 'message' );
  }
};

subtest 'the error names the query of the failed call' => sub {
  my $ua = WWW::Picnic::MockUA->new;
  $ua->add_response('user/login', WWW::Picnic::MockUA::sample_login_response(),
    headers => { 'X-Picnic-Auth' => 'mock-auth-token-12345' });
  $ua->add_response('search-page-results', undef, status => 500, raw => 'boom');
  my $p = WWW::Picnic->new(
    user => $fake_user, pass => $fake_pass, country => $fake_country, http_agent => $ua,
  );

  my $err = do { eval { $p->search('haribo') }; $@ };
  my $attributes = error_attributes($err);
  ok( $attributes, 'the failed call throws a WWW::Picnic::Error' );
  SKIP: {
    skip 'no WWW::Picnic::Error to look at', 2 unless $attributes;
    is( $attributes->{path}, '/api/15/pages/search-page-results?search_term=haribo',
      'path with the query' );
    is( $attributes->{method}, 'GET', 'method' );
  }
};

subtest 'an answer that is no JSON is an error' => sub {
  my $ua = WWW::Picnic::MockUA->new;
  $ua->add_response('user/login', WWW::Picnic::MockUA::sample_login_response(),
    headers => { 'X-Picnic-Auth' => 'mock-auth-token-12345' });
  $ua->add_response('cart$', undef, raw => 'this is no JSON');
  my $p = WWW::Picnic->new(
    user => $fake_user, pass => $fake_pass, country => $fake_country, http_agent => $ua,
  );

  my $err = do { eval { $p->get_cart }; $@ };
  ok( blessed($err), 'the failed call throws an object' );
  is( ref $err, 'WWW::Picnic::Error', 'the object is a WWW::Picnic::Error' );
  my $attributes = error_attributes($err);
  SKIP: {
    skip 'no WWW::Picnic::Error to look at', 4 unless $attributes;
    is( $attributes->{message}, 'HTTP 200: the answer was no JSON', 'message' );
    is( $attributes->{status}, 200, 'status' );
    is( $attributes->{method}, 'GET', 'method' );
    is( $attributes->{path}, '/api/15/cart', 'path' );
  }
};

subtest 'an empty answer is an error' => sub {
  my $ua = WWW::Picnic::MockUA->new;
  $ua->add_response('user/login', WWW::Picnic::MockUA::sample_login_response(),
    headers => { 'X-Picnic-Auth' => 'mock-auth-token-12345' });
  $ua->add_response('cart$', undef, raw => '');
  my $p = WWW::Picnic->new(
    user => $fake_user, pass => $fake_pass, country => $fake_country, http_agent => $ua,
  );

  my $err = do { eval { $p->get_cart }; $@ };
  my $attributes = error_attributes($err);
  ok( $attributes, 'the failed call throws a WWW::Picnic::Error' );
  SKIP: {
    skip 'no WWW::Picnic::Error to look at', 3 unless $attributes;
    is( $attributes->{message}, 'HTTP 200: the answer was empty', 'message' );
    is( $attributes->{status}, 200, 'status' );
    is( $attributes->{path}, '/api/15/cart', 'path' );
  }
};

subtest 'an empty answer at the login is an error' => sub {
  my $ua = WWW::Picnic::MockUA->new;
  $ua->add_response('user/login', undef, raw => '');
  my $p = WWW::Picnic->new(
    user => $fake_user, pass => $fake_pass, country => $fake_country, http_agent => $ua,
  );

  my $err = do { eval { $p->login }; $@ };
  my $attributes = error_attributes($err);
  ok( $attributes, 'the failed call throws a WWW::Picnic::Error' );
  SKIP: {
    skip 'no WWW::Picnic::Error to look at', 3 unless $attributes;
    is( $attributes->{message}, 'HTTP 200: the answer was empty', 'message' );
    is( $attributes->{method}, 'POST', 'method' );
    is( $attributes->{path}, '/api/15/user/login', 'path' );
  }
};

subtest 'the 2FA verify checks the body' => sub {
  my $ua = WWW::Picnic::MockUA->new;
  $ua->add_response('user/login', WWW::Picnic::MockUA::sample_login_2fa_response(),
    headers => { 'X-Picnic-Auth' => 'pending-token' });
  $ua->add_response('user/2fa/generate', {});
  $ua->add_response('user/2fa/verify', undef, raw => 'this is no JSON',
    headers => { 'X-Picnic-Auth' => 'final-token' });
  my $p = WWW::Picnic->new(
    user => $fake_user, pass => $fake_pass, country => $fake_country, http_agent => $ua,
  );

  $p->login;
  $p->generate_2fa_code;
  my $err = do { eval { $p->verify_2fa_code('123456') }; $@ };
  my $attributes = error_attributes($err);
  ok( $attributes, 'the failed call throws a WWW::Picnic::Error' );
  SKIP: {
    skip 'no WWW::Picnic::Error to look at', 4 unless $attributes;
    is( $attributes->{message}, 'HTTP 200: the answer was no JSON', 'message' );
    is( $attributes->{status}, 200, 'status' );
    is( $attributes->{method}, 'POST', 'method' );
    is( $attributes->{path}, '/api/15/user/2fa/verify', 'path' );
  }
};

subtest 'the product id is sent as one path segment' => sub {
  my $ua = WWW::Picnic::MockUA->new;
  $ua->add_response('user/login', WWW::Picnic::MockUA::sample_login_response(),
    headers => { 'X-Picnic-Auth' => 'mock-auth-token-12345' });
  $ua->add_response('articles/', WWW::Picnic::MockUA::sample_article_response());
  my $p = WWW::Picnic->new(
    user => $fake_user, pass => $fake_pass, country => $fake_country, http_agent => $ua,
  );

  my $article = $p->get_article('a b/c');
  isa_ok( $article, 'WWW::Picnic::Result::Article' );
  my @requests = $ua->all_requests;
  is( $requests[-1]->uri->path, '/api/15/articles/a%20b%2Fc',
    'the id is one escaped segment' );
};

subtest 'a product id with a slash stays in the segment' => sub {
  my $ua = WWW::Picnic::MockUA->new;
  $ua->add_response('user/login', WWW::Picnic::MockUA::sample_login_response(),
    headers => { 'X-Picnic-Auth' => 'mock-auth-token-12345' });
  $ua->add_response('articles/', WWW::Picnic::MockUA::sample_article_response());
  my $p = WWW::Picnic->new(
    user => $fake_user, pass => $fake_pass, country => $fake_country, http_agent => $ua,
  );

  my $err = do { eval { $p->get_article('../cart') }; $@ };
  is( $err, '', 'the call does not croak' );
  my @requests = $ua->all_requests;
  is( $requests[-1]->uri->path, '/api/15/articles/..%2Fcart',
    'the id stays in the segment' );
};

subtest 'a product id that is a dot segment is refused' => sub {
  my $ua = WWW::Picnic::MockUA->new;
  $ua->add_response('user/login', WWW::Picnic::MockUA::sample_login_response(),
    headers => { 'X-Picnic-Auth' => 'mock-auth-token-12345' });
  $ua->add_response('articles/', WWW::Picnic::MockUA::sample_article_response());
  my $p = WWW::Picnic->new(
    user => $fake_user, pass => $fake_pass, country => $fake_country, http_agent => $ua,
  );

  for my $id ( '', '.', '..' ) {
    my $err = do { eval { $p->get_article($id) }; $@ };
    ok( $err, "$id is refused" );
  }

  for my $id ( '.', '..' ) {
    my $err = do { eval { $p->get_article($id) }; $@ };
    like( $err, qr/cannot be empty, '\.' or '\.\.'/, "$id: the message names the reason" );
  }
};

subtest 'the arguments of the product methods are checked' => sub {
  my $ua = WWW::Picnic::MockUA->new;
  $ua->add_response('user/login', WWW::Picnic::MockUA::sample_login_response(),
    headers => { 'X-Picnic-Auth' => 'mock-auth-token-12345' });
  $ua->add_response('articles/', WWW::Picnic::MockUA::sample_article_response());
  $ua->add_response('cart/add_product', WWW::Picnic::MockUA::sample_cart_response());
  $ua->add_response('cart/remove_product', WWW::Picnic::MockUA::sample_cart_response());
  $ua->add_response('cart/set_delivery_slot', WWW::Picnic::MockUA::sample_cart_response());
  $ua->add_response('search-page-results', WWW::Picnic::MockUA::sample_search_response());
  my $p = WWW::Picnic->new(
    user => $fake_user, pass => $fake_pass, country => $fake_country, http_agent => $ua,
  );

  my @methods = (
    [ 'get_article',       'product_id', sub { $p->get_article(@_) } ],
    [ 'add_to_cart',      'product_id', sub { $p->add_to_cart(@_) } ],
    [ 'remove_from_cart', 'product_id', sub { $p->remove_from_cart(@_) } ],
    [ 'set_delivery_slot','slot_id',    sub { $p->set_delivery_slot(@_) } ],
    [ 'search',           'term',       sub { $p->search(@_) } ],
  );

  for my $method ( @methods ) {
    my ( $name, $argument, $code ) = @$method;

    my $undef_err = do { eval { $code->(undef) }; $@ };
    ok( $undef_err, "$name: an undefined $argument is refused" );
    like( $undef_err, qr/^\Q$name\E: \Q$argument\E is required/,
      "$name: the message names the method and the argument" );

    my $empty_err = do { eval { $code->('') }; $@ };
    ok( $empty_err, "$name: an empty $argument is refused" );
    like( $empty_err, qr/^\Q$name\E: \Q$argument\E must not be empty/,
      "$name: the message names the method and the argument" );
  }
};

subtest 'the count of the cart methods is checked' => sub {
  my $ua = WWW::Picnic::MockUA->new;
  $ua->add_response('user/login', WWW::Picnic::MockUA::sample_login_response(),
    headers => { 'X-Picnic-Auth' => 'mock-auth-token-12345' });
  $ua->add_response('cart/add_product', WWW::Picnic::MockUA::sample_cart_response());
  $ua->add_response('cart/remove_product', WWW::Picnic::MockUA::sample_cart_response());
  my $p = WWW::Picnic->new(
    user => $fake_user, pass => $fake_pass, country => $fake_country, http_agent => $ua,
  );

  my @methods = (
    [ 'add_to_cart',      sub { $p->add_to_cart(@_) } ],
    [ 'remove_from_cart', sub { $p->remove_from_cart(@_) } ],
  );

  # Zero, a negative number, a fraction and free text are no counts.
  my @bad_counts = ( 0, -1, 1.5, 'abc', '2x' );
  for my $method ( @methods ) {
    my ( $name, $code ) = @$method;

    for my $count ( @bad_counts ) {
      my $err = do { eval { $code->( 'product-1', $count ) }; $@ };
      ok( $err, "$name: the count $count is refused" );
      like( $err, qr/^\Q$name\E: count must be a positive integer/,
        "$name: the message names the method and the count" );
    }
  }

  # The default of one, a number and the digits of the command line are counts.
  my $cart = $p->add_to_cart('product-1');
  isa_ok($cart, 'WWW::Picnic::Result::Cart');
  like( ($ua->all_requests)[-1]->content, qr/"count"\s*:\s*1/, 'the default count is one' );

  $p->remove_from_cart('product-1', 3);
  like( ($ua->all_requests)[-1]->content, qr/"count"\s*:\s*3/, 'the count is sent' );

  $p->add_to_cart('product-1', '4');
  like( ($ua->all_requests)[-1]->content, qr/"count"\s*:\s*"?4"?/, 'the count of the command line is sent' );
};

done_testing;

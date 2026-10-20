requires 'HTTP::Message';
requires 'JSON::MaybeXS';
requires 'LWP::Protocol::https';
requires 'LWP::UserAgent';
requires 'Moo';
requires 'URI';
requires 'namespace::clean';

on test => sub {
  requires 'Test::More';
};

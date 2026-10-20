requires 'HTTP::Message';
requires 'JSON::MaybeXS';
requires 'LWP::Protocol::https';
requires 'LWP::UserAgent';
requires 'Moo';
requires 'namespace::clean';
requires 'URI';

on test => sub {
  requires 'Test::More';
};

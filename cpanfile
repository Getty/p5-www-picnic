
requires 'JSON::MaybeXS', '0';
requires 'HTTP::Message', '0';
requires 'LWP::Protocol::https', '0';
requires 'LWP::UserAgent', '0';
requires 'Moo', '0';
requires 'namespace::clean', '0';
requires 'URI', '0';

on test => sub {
  requires 'Test::More', '0';
};

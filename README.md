# WWW-Picnic

[![CPAN Version](https://img.shields.io/cpan/v/WWW-Picnic.svg)](https://metacpan.org/pod/WWW::Picnic)
[![License](https://img.shields.io/cpan/l/WWW-Picnic.svg)](https://metacpan.org/pod/WWW::Picnic)

Perl library to access the Picnic Supermarket API.

**WORK IN PROGRESS**

## Installation

```bash
cpanm WWW::Picnic
```

## Usage

```perl
use WWW::Picnic;

my $picnic = WWW::Picnic->new(
    user    => 'user@example.com',
    pass    => 'password',
    country => 'de',
);

my $cart = $picnic->get_cart;
my $slots = $picnic->get_delivery_slots;
my $results = $picnic->search('Milch');
```

## License

This is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

## Author

Torsten Raudssus <torsten@raudssus.de> ([GETTY](https://metacpan.org/author/GETTY))

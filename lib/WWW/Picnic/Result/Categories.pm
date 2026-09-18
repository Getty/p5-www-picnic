package WWW::Picnic::Result::Categories;
# ABSTRACT: Collection of Picnic store categories
our $VERSION = '0.102';
use Moo;

extends 'WWW::Picnic::Result';

=head1 SYNOPSIS

    my $categories = $picnic->get_categories;
    say "Found ", $categories->total_count, " categories";

    for my $category ($categories->all_categories) {
        say $category->{name};
    }

=head1 DESCRIPTION

Container for the product categories returned by the store landing
(C<my_store>) endpoint. Provides access to the list of category entries.

=cut

has catalog => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('catalog') || [] },
);

=attr catalog

Arrayref of category entries from the store landing response.

=cut

sub all_categories {
  my ( $self ) = @_;
  return @{ $self->catalog };
}

=method all_categories

Returns list of all category entries (as opposed to arrayref).

=cut

sub total_count {
  my ( $self ) = @_;
  return scalar @{ $self->catalog };
}

=method total_count

Returns total number of categories.

=cut

1;

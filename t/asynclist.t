use Mojo::Base -strict;
use Mojo::AsyncList;
use Test::More;

my $item_cb = sub {
  my ($async_list, $username, $gather_cb) = @_;
  Mojo::IOLoop->timer(
    rand(0.5) => sub { $gather_cb->(undef, "got:$username", "foo") });
};

my @res;
my @items      = qw(supergirl superman batman);
my $async_list = Mojo::AsyncList->new($item_cb, sub { shift; @res = @_ });

$async_list->concurrent(2);
$async_list->process(\@items);

my ($finish, $item, $result) = (0, 0, 0);
$async_list->on(finish => sub { $finish++ });
$async_list->on(item   => sub { $item++ });
$async_list->on(result => sub { $result++ });

$async_list->wait;

is $finish, 1, 'finished once';
is $item,   int @items, 'item';
is $result, int @items, 'result';
is_deeply \@res, [map { ["got:$_", "foo"] } @items], 'res';

done_testing;

# NAME

Mojo::AsyncList - Process a list with callbacks

# SYNOPSIS

    use Mojo::AsyncList;
    use Mojo::mysql;

    my $mysql = Mojo::mysql->new;
    my $db    = $mysql->db;

    my $async_list = Mojo::AsyncList->new(
      sub { # Specify a "item" event handler
        my ($async_list, $username, $gather_cb) = @_;
        $db->select("users", {username => $username}, $gather_cb);
      },
      sub { # Specify a "finish" event handler
        my $async_list = shift;
        warn $_->[0]{user_id} for @_; # @_ = ([$db_res_supergirl], [$db_res_superman], ...)
      },
    );

    my @users = qw(supergirl superman batman);
    $async_list->concurrent(2);
    $async_list->process(\@users);
    $async_list->wait;

# DESCRIPTION

[Mojo::AsyncList](https://metacpan.org/pod/Mojo::AsyncList) is a module that can asynchronously process a list of items
with callback.

# EVENTS

## finish

    $async_list->on(finish => sub { my ($async_list, @all_res) = @_; });

Emitted when ["process"](#process) is done with all the `$items`. `@all_res` is a list
of array-refs, where each item is `@res` passed on to ["result"](#result).

## item

    $async_list->on(item => sub { my ($async_list, $item, $gather_cb) = @_; });

Used to process the next `$item` in `$items` passed on to ["process"](#process).

## result

    $async_list->on(result => sub { my ($async_list, @res) = @_; });

Emitted when a new result is ready, `@res` contains the data passed on to
`$gather_cb`.

# ATTRIBUTES

## concurrent

    $int        = $async_list->concurrent;
    $async_list = $async_list->concurrent(0);

Used to set the number of concurrent items to process. Default value is zero,
which means "process all items" at once.

Used to see how many items that is processing right now.

## offset

    $int        = $async_list->offset;
    $async_list = $async_list->offset(1);

Will remove the number of arguments passed on to &lt;$gather\_cb>, used in the
["item"](#item) event. Default to "1", meaning it will remove the invocant.

# METHODS

## new

    $async_list = Mojo::AsyncList->new;
    $async_list = Mojo::AsyncList->new(@attrs);
    $async_list = Mojo::AsyncList->new(\%attrs);
    $async_list = Mojo::AsyncList->new($item_cb, $finish_cb);
    $async_list = Mojo::AsyncList->new($item_cb, $finish_cb, \%attrs);

Used to create a new [Mojo::AsyncList](https://metacpan.org/pod/Mojo::AsyncList) object. ["item"](#item) and [finish](https://metacpan.org/pod/finish) event
callbacks can be provided when constructing the object.

## process

    $async_list = $async_list->process(@items);
    $async_list = $async_list->process([@items]);

Process `$items` and emit ["EVENTS"](#events) while doing so.

## stats

    $int          = $async_list->stats("done");
    $int          = $async_list->stats("remaining");
    $gettimeofday = $async_list->stats("t0");
    $hash_ref     = $async_list->stats;

Used to extract stats while items are processing. This can be useful inside the
["EVENTS"](#events), or within a recurring timer:

    Mojo::IOLoop->recurring(1 => sub {
      warn sprintf "[%s] done: %s\n", time, $async_list->stats("done");
    });

Changing the `$hash_ref` will have fatal consequences.

## wait

    $async_list->concurrent(2)->process(\@items)->wait;
    $async_list->wait;

Used to block and wait until [Mojo::AsyncList](https://metacpan.org/pod/Mojo::AsyncList) is done with the `$items`
passed on to ["process"](#process).

# AUTHOR

Jan Henning Thorsen

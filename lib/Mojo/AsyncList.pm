package Mojo::AsyncList;
use Mojo::Base 'Mojo::EventEmitter';

use Time::HiRes ();

has concurrent => 0;
has offset     => 1;

sub new {
  my $class     = shift;
  my $item_cb   = ref $_[0] eq 'CODE' ? shift : undef;
  my $finish_cb = ref $_[0] eq 'CODE' ? shift : undef;
  my $self      = $class->SUPER::new(@_);

  $self->on(item   => $item_cb)   if $item_cb;
  $self->on(finish => $finish_cb) if $finish_cb;

  return $self;
}

sub process {
  my ($self, $items) = @_;
  my $remaining = int @$items;
  my ($gather_cb, $item_pos, $pos, @res) = (undef, 0, 0);

  $gather_cb = sub {
    my $res_pos = $pos++;

    return sub {
      shift for 1 .. $self->offset;
      $remaining--;
      $res[$res_pos] = [@_];
      $self->emit(result => @_);
      return $self->emit(finish => @res) unless $remaining;
      return $self->emit(item   => $items->[$item_pos++], $gather_cb->())
        if $item_pos < @$items;
    };
  };

  $self->emit(item => $items->[$item_pos++], $gather_cb->())
    for 1 .. ($self->concurrent || @$items);

  return $self;
}

1;

=head1 NAME

Mojo::AsyncList - Process a list with callbacks

=head1 SYNOPSIS

  use Mojo::AsyncList;
  use Mojo::mysql;

  my $mysql = Mojo::mysql->new;
  my $db    = $mysql->db;

  my $async_list = Mojo::AsyncList->new(
    sub { # Specify a "item" event handler
      my ($async_list, $username, $gather_cb) = @_;
      $db->select({username => $username}, $gather_cb);
    },
    sub { # Specify a "finish" event handler
      my $async_list = shift;
      warn $_->[0]{user_id} for @_; # @_ = ([$db_res_supergirl], [$db_res_superman], ...)
    },
  );

  my @users = qw(supergirl superman batman);
  $async_list->concurrent(2);
  $async_list->process(\@users);

=head1 DESCRIPTION

L<Mojo::AsyncList> is a module that can asynchronously process a list of items
with callback.

=head1 EVENTS

=head2 finish

  $async_list->on(finish => sub { my ($async_list, @all_res) = @_; });

Emitted when L</process> is done with all the C<$items>. C<@all_res> is a list
of array-refs, where each item is C<@res> passed on to L</result>.

=head2 item

  $async_list->on(item => sub { my ($async_list, $item, $gather_cb) = @_; });

Used to process the next C<$item> in C<$items> passed on to L</process>.

=head2 result

  $async_list->on(result => sub { my ($async_list, @res) = @_; });

Emitted when a new result is ready, C<@res> contains the data passed on to
C<$gather_cb>.

=head1 ATTRIBUTES

=head2 concurrent

  $int        = $async_list->concurrent;
  $async_list = $async_list->concurrent(0);

Used to set the number of concurrent items to process. Default value is zero,
which means "process all items" at once.

Used to see how many items that is processing right now.

=head2 offset

  $int        = $async_list->offset;
  $async_list = $async_list->offset(1);

Will remove the number of arguments passed on to <$gather_cb>, used in the
L</item> event. Default to "1", meaning it will remove the invocant.

=head1 METHODS

=head2 process

  $async_list = $async_list->process(@items);
  $async_list = $async_list->process([@items]);

Process C<$items> and emit L</EVENTS> while doing so.

=head1 AUTHOR

Jan Henning Thorsen

=cut

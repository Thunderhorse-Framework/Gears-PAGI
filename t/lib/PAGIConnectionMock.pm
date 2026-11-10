package PAGIConnectionMock;

use v5.40;
use Future;

sub new ($class)
{
	return bless {}, $class;
}

sub is_connected ($self)
{
	return true;
}

sub disconnect_reason ($self)
{
	return undef;
}

sub disconnect_detail ($self)
{
	return undef;
}

sub close_code ($self)
{
	return undef;
}

sub close_reason ($self)
{
	return undef;
}

sub on_disconnect ($self, $cb)
{
}

sub on_complete ($self, $cb)
{
}

sub response_started ($self)
{
	return false;
}

sub response_complete ($self)
{
	return false;
}

sub disconnect_future ($self)
{
	return Future->new;
}

sub on_end ($self, $cb)
{
}

sub end_future ($self)
{
	return Future->new;
}

sub abort ($self, $detail)
{
}


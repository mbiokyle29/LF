#!/usr/bin/env perl
use Mojolicious::Lite;
use Mango;

my $mango = Mango->new('mongodb://found:mojo@linus.mongohq.com:10089/LF');
my $db = $mango->db;
my $losts = $db->collection('Lost');
my $id = $losts->insert({bar => 'foo'});

get '/' => sub {
  my $self = shift;
  $self->render(text => $id);
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
Lost and Found endpoint

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>

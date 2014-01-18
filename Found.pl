#!/usr/bin/env perl
use Mojolicious::Lite;
use Mango;

my $mango = Mango->new('mongodb://found:mojo@linus.mongohq.com:10089/LF');
my $db = $mango->db;

my $losts = $db->collection('Lost');
my $founds = $db->collection('Found');

my $lost_c = Mango::Cursor->new(collection => $losts);
my $lost_docs = $lost_c->all;
my $found_c = Mango::Cursor->new(collection => $founds);
my $found_docs = $found_c->all;

get '/' => sub
{
  my $self = shift;
  $self->render('index');
};

get '/ios-7/end/lost' => sub { shift->render(json => $lost_docs ) };
get '/ios-7/end/found' => sub { shift->render(json => $found_docs ) };

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

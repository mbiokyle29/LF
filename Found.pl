#!/usr/bin/env perl
use Mojolicious::Lite;
use MongoDB;
use MongoDB::OID;
use MongoDB::Cursor;
use Data::Dumper;

my $mongo_client = MongoDB::MongoClient->new
(
  host => 'linus.mongohq.com',
  port => 10089,
  db_name => 'LF',
  username => 'found',
  password => 'mojo',
);

my $db = $mongo_client->get_database('LF');

my $losts = $db->get_collection('Lost');
my $founds = $db->get_collection('Found');

my @all_losts = ($losts->query({}))->all;
my @all_founds = ($founds->query({}))->all;

get '/' => sub
{
  my $self = shift;
  $self->render(text => 'Lost and Found End Point');
};

get '/ios-7/end/lost' => sub { shift->render(json => \@all_founds) };
get '/ios-7/end/found' => sub { shift->render(json => \@all_losts ) };


app->start;
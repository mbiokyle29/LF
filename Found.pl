#!/usr/bin/env perl
use Mojolicious::Lite;
use MongoDB;
use MongoDB::OID;
use String::Approx 'amatch';

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

post '/run' => sub { &match_maker; shift->render(text => 'YEAH'); };

get '/ios-7/end/lost' => sub { shift->render(json => \@all_founds) };
get '/ios-7/end/found' => sub { shift->render(json => \@all_losts ) };

sub match_maker
{
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
  my $lost_c = $losts->query( {Matched => 0} );

  while(my $lost = $lost_c->next)
  {
    my $lost_ref = MongoDB::DBRef->new( db => 'LF', ref => $losts, id => $lost->{_id} );
    my $best_ref;
    my $most_matches = 0;

    my $found_c = $founds->query({Matched => 0});
    while(my $found = $found_c->next)
    {
      my $matches;
      my $found_ref = MongoDB::DBRef->new( db => 'LF', ref => $founds, id => $found->{_id} );
      if(amatch($lost->{Location},["i"],$found->{Location}))
      {
        foreach my $tag (@{$lost->{'Tags'}})
        {
          my $count = amatch($tag,["i"], @{$found->{Tags}});
          $matches+=$count;
        }
      }
      if($matches && $matches > $most_matches) {  $most_matches = $matches; $best_ref = $found_ref; }
    }
    if($best_ref)
    {
      $losts->update({ _id => $lost_ref->id }, { '$set' => { Matched => 1, Match_id => $best_ref->id } }, { 'upsert' => 1 } );
      $founds->update({ _id => $best_ref->id }, { '$set' => { Matched => 1, Match_id => $lost_ref->id } }, { 'upsert' => 1 } );
    }
  }
}
app->start;
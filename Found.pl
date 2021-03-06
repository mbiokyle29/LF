#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo::UserAgent;
use MongoDB;
use MongoDB::OID;
use String::Approx 'amatch';
use WebService::Dwolla;

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
my $users = $db->get_collection('users');

get '/' => sub
{
  my $self = shift;
  $self->render('index');
};

post '/run' => sub
{
  &match_maker();
  shift->render(text => "YEA");
};

post '/no' => sub
{
  my $self = shift;
  my $rej_ref = $self->param('Reject');
  my $lost_ref = $self->param('Lost');
  my $lost_oid = new MongoDB::OID(value => $lost_ref);
  my $rej_oid = new MongoDB::OID(value => $rej_ref);
  $losts->update
  (
    { _id => $lost_oid },
    {
      '$push' => { Rejects => $rej_oid },
      '$pull' => { PMatch_id => $rej_oid }
    },

    { 'upsert' => 1 }
  );
  $self->render(text => 'YEAH');
};

post '/yes' => sub
{
  my $self = shift;
  my $found_ref = $self->param('Found');
  my $lost_ref = $self->param('Lost');
  my $found_oid = new MongoDB::OID(value => $found_ref);
  my $lost_oid = new MongoDB::OID(value => $lost_ref);
  $losts->update
  (
    { _id => $lost_oid },
    {
      '$set' => { Matched => 1 },
      '$pull' => { PMatch_id => $found_oid }
    },
  );
  $founds->update
  (
    { _id => $found_oid },
    {
      '$set' => { Matched => 1 },
      '$pull' => { PMatch_id => $lost_oid }
    },
  );
  $self->render(text => 'YEAH');
};

get '/ios-7/end/lost' => sub
{
  my @all_losts = ($losts->query({}))->all;
  shift->render(json => \@all_losts )
};

get '/ios-7/end/found' => sub
{
  my @all_founds = ($founds->query({}))->all;
  shift->render(json => \@all_founds)
};

any '/ios-7/end/insert-lost' => sub
{
  my $self = shift;
  my $req = $self->tx->req;
  my $hash = $req->json;

  #ITEM
  my $item = $hash->{'Item'};
  #EMAIL
  my $email = $hash->{'email'};
  #DESC
  my $desc = $hash->{'Description'};
  #LOC
  my $loc = $hash->{'Location'};
  #TAGS
  my @tags = @{ $hash->{'Tags'}};

  my $its_in = $users->count({Email => $email});
  unless($its_in)
  {
    $email =~ m/^(\w+)@(.+)$/;
    my $first_name = $1;
    my $last_name = $2;
    $users->insert
    (
      {
        "email" => $email,
        "first" => $first_name,
        "last" => $last_name,
      }
    );
  }

  ## INSERT ##
  $losts->insert
  (
    {
      "Item" => $item,
      "email" => $email,
      "Description" => $desc,
      "Location" => $loc,
      "Tags" => @tags,
    }
  );
  $self->render(text => $hash->{'Test'});
};

any '/ios-7/end/insert-found' => sub
{
  my $self = shift;
  my $req = $self->tx->req;
  my $hash = $req->json;

  #ITEM
  my $item = $hash->{'Item'};
  #EMAIL
  my $email = $hash->{'email'};
  #DESC
  my $desc = $hash->{'Description'};
  #LOC
  my $loc = $hash->{'Location'};
  #TAGS
  my @tags = @{ $hash->{'Tags'}};

  my $its_in = $users->count({Email => $email});
  unless($its_in)
  {
    $email =~ m/^(\w+)@(.+)$/;
    my $first_name = $1;
    my $last_name = $2;
    $users->insert
    (
      {
        "email" => $email,
        "first" => $first_name,
        "last" => $last_name,
      }
    );
  }

  ## INSERT ##
  $founds->insert
  (
    {
      "Item" => $item,
      "email" => $email,
      "Description" => $desc,
      "Location" => $loc,
      "Tags" => @tags,
    }
  );
  $self->render(text => "OKAY");
};

sub match_maker
{
  my @unimp = qw(the of to and a in is it you that he was for on are with as I his they be at one have and this);
  my $lost_c = $losts->query( {Matched => 0} );

  while(my $lost = $lost_c->next)
  {

    # Keep a static ref to current lost record
    my $lost_ref = MongoDB::DBRef->new( db => 'LF', ref => $losts, id => $lost->{_id} );
    my $best_ref;
    my $best_total = 0;

    # Lost record values
    my $l_desc = $lost->{Description};
    my $l_item = $lost->{Item};
    my @l_tags = @{ $lost->{Tags}};
    my @loc = @{$lost->{location}{coordinates}};
    my @l_PM = @{ $lost->{PMatch_id} };
    my @l_R = @{ $lost->{Rejects} };

    my $found_c = $founds->query
    (
      {
        Matched => 0,
        location =>
        {
          '$nearSphere' =>
          {
            '$geometry' => { type => "Point", coordinates => [$loc[0],$loc[1]] }
          },
          '$maxDistance' => 10
         }
       }
   );

   while(my $found = $found_c->next)
   {
      my $black_list = 0;
      foreach my $arr (@l_PM) { if($arr->{value} eq $found->{_id}->{value}) { $black_list = 1; } }
      foreach my $arr (@l_R) { if($arr->{value} eq $found->{_id}->{value}) { $black_list = 1; } }
      next if($black_list);

      my $found_ref = MongoDB::DBRef->new( db=> 'LF', ref => $founds, id => $found->{_id} );

      # Found Vars for matching
      my $f_desc = $found->{Description};
      my $f_item = $found->{Item};
      my @f_tags = @{ $found->{Tags}};

      my $total = 0;
        foreach my $tagl (@l_tags)
        {
          $tagl =~ s/\s//g;
          next if( (length($tagl) < 2) || grep(/^$tagl$/, @unimp) );
          foreach my $tagf (@f_tags)
          {
            $tagf =~ s/^\s//g;
            next if( (length($tagf) < 2) || grep(/^$tagf$/, @unimp) );
            if(lc($tagl) eq lc($tagf))    { $total++;   next; }
            if(amatch($tagl,["i"],$tagf)) { $total+=.9; next; }
            if(index($tagl, $tagf) != -1) { $total+=.2; next; }
            if(index($tagf, $tagl) != -1) { $total+=.2; next; }
          }
        }
        if($total > $best_total) { $best_total = $total; $best_ref = $found_ref; }
    }

    if($best_ref && $best_total > 1)
    {
      #next if($lost_ref->{Pmatch_id})
      $losts->update(  { _id => $lost_ref->{id} }, { '$push' => { PMatch_id => $best_ref->{id} } },  { 'upsert' => 1 } );
      $founds->update( { _id => $best_ref->{id} }, { '$push' => { PMatch_id => $lost_ref->{id} } },  { 'upsert' => 1 } );
    }
  }
}

app->start;

__DATA__
@@index.html.ep
  <div style="margin-left:auto;margin-right:auto;">
    <h1>Lost and Found MatchMaker Backend</h1>
    <image src="http://jozef.warum.net/img/perl-5-raptor.png">
  </div>

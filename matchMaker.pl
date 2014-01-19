#!/usr/bin/perl
use warnings;
use strict;
use MongoDB;
use MongoDB::OID;
use String::Approx 'amatch';
use feature 'say';

my @unimp = qw(the of to and a in is it you that he was for on are with as I his they be at one have and this);

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

## TODO Implement skipping
while(my $lost = $lost_c->next)
{
  my $lost_ref = MongoDB::DBRef->new( db => 'LF', ref => $losts, id => $lost->{_id} );
  my $best_ref;
  my $best_total = 0;

  # Lost Vars for matching
  my $l_loc = $lost->{Location};
  my $l_desc = $lost->{Description};
  my $l_item = $lost->{Item};
  my @l_tags = @{ $lost->{Tags}};

  my $found_c = $founds->query({Matched => 0});

  while(my $found = $found_c->next)
  {
    my $found_ref = MongoDB::DBRef->new( db => 'LF', ref => $founds, id => $found->{_id} );

    # Found Vars for matching
    my $f_loc = $found->{Location};
    my $f_desc = $found->{Description};
    my $f_item = $found->{Item};
    my @f_tags = @{ $found->{Tags}};

    my $total = 0;

    if(amatch($l_loc,["i"],$f_loc))
    {
      say "Locations matched";
      say "Lets check tags";
      foreach my $tagl (@l_tags)
      {
        $tagl =~ s/\s//g;
        next if( (length($tagl) < 2) || grep(/^$tagl$/, @unimp) );
        foreach my $tagf (@f_tags)
        {
          $tagf =~ s/^\s//g;
          next if( (length($tagf) < 2) || grep(/^$tagf$/, @unimp) );
          say "Checking lost tag $tagl against $tagf";
          if(amatch($tagl,["i"],$tagf))
          {
            say "l tag $tagl is a match for r tag $tagf";
            $total+=.9;
            if(lc($tagl) eq lc($tagf))    { $total++; }
            if(index($tagl, $tagf) != -1) { $total+=.2; }
            if(index($tagf, $tagl) != -1) { $total+=.2; }
          }
        }
      }
      say $total;
      if($total > 1)
      {
      $losts->update({ _id => $lost_ref->{id} }, { '$set' => { Matched => 1, PMatch_id => $best_ref->{id} } }, { 'upsert' => 1 } );
      $founds->update({ _id => $best_ref->{id} }, { '$set' => { Matched => 1, PMatch_id => $lost_ref->{id} } }, { 'upsert' => 1 } );
      }
    }
  }
}

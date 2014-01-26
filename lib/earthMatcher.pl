#!/usr/bin/perl
use warnings;
use strict;
use MongoDB;
use MongoDB::OID;
use String::Approx 'amatch';

my $mongo_client = MongoDB::MongoClient->new
(
  host => 'widmore.mongohq.com',
  port => 10010,
  db_name => 'Geo_test',
  username => 'found',
  password => 'mojo',
);

my $db = $mongo_client->get_database('Geo_test');

my $losts = $db->get_collection('Lost');
my $founds = $db->get_collection('Found');
&match_maker;

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
    my @loc = @{$lost->{loc}{coordinates}};
    my @l_PM;
    my @l_R;

    # If record as a PMatch_id  TODO TODO
    if($lost->{PMatch_id}) { @l_PM = @{ $lost->{PMatch_id} }; }

    # Same as above TODO TODO TODO
    if($lost->{Rejects}) { @l_R = @{ $lost->{Rejects} }; }

    my $found_c = $founds->query
    (
      {
        Matched => 0,
        loc =>
        {
          '$nearSphere' =>
          {
            '$geometry' => { type => "Point", coordinates => [10,-10] }
          },
          '$maxDistance' => 10
         }
       }
   );

   while(my $found = $found_c->next)
   {
      my $black_list = 0;

      if(@l_PM)
      {
        foreach my $arr (@l_PM) { if($arr->{value} eq $found->{_id}->{value}) { $black_list = 1; } }
      }

      if(@l_R)
      {
        foreach my $arr (@l_R) { if($arr->{value} eq $found->{_id}->{value}) { $black_list = 1; } }
      }

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
return 1;

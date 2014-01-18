#!/usr/bin/perl
use warnings;
use strict;
use Mango;
use Mango::BSON ':bson';
use Data::Dumper;
use String::Approx 'amatch';
use List::Util 'max';

my $mango = Mango->new('mongodb://found:mojo@linus.mongohq.com:10089/LF');
my $db = $mango->db;

my $losts = $db->collection('Lost');
my $founds = $db->collection('Found');

my $lost_c = Mango::Cursor->new
(
  collection => $losts,
  query => {Matched => 0},
);
my $found_c = Mango::Cursor->new
(
  collection => $founds,
  query => {Matched => 0}
);

while(my $lost = $lost_c->next)
{
  my $item_l = $$lost{'Item'};
  my $loc_l = $$lost{'Found_Location'};
  my @tags_l = @{$$lost{'Tags'}};
  my $lost_id = $$lost{'_id'}{'oid'};
  my %match_scores;

  while(my $found = $found_c->next)
  {
    my $matches = 0;
    my $item_f = $$found{'Item'};
    my $loc_f = $$found{'Found_Location'};
    my @tags_f = @{$$lost{'Tags'}};
    my $id = $$found{'_id'}{'oid'};

    ## Main Match Loop
    if(amatch($loc_l,["i"],$loc_f))
    {
      foreach my $tag (@tags_l)
      {
        my $count = amatch($tag,["i"], @tags_f);
        $matches+=$count;
      }
    }
    if($matches) { $match_scores{$id} = $matches; }
  }
  my $highest = 0;
  my $highest_id = "";
  foreach my $id (keys(%match_scores))
  {
    if($match_scores{$id} > $highest)
    {
      $highest = $match_scores{$id};
      $highest_id = $id;
    }
  }

  print "$highest_id matches $lost_id";

  my $found_oid = bson_oid($highest_id);
  $losts->update({_id => $lost_oid}, {Matched => 1, Match_id => $highest_id });
  $founds->update({_id => $found_oid}, {Matched => 1, Match_id => $lost_id});
}
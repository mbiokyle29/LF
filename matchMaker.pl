#!/usr/bin/perl
use warnings;
use strict;
use Mango;
use Data::Dumper;
use String::Approx 'amatch';

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
  while(my $found = $found_c->next)
  {
    my $matches = 0;
    my $item_f = $$found{'Item'};
    my $loc_f = $$found{'Found_Location'};
    my @tags_f = @{$$lost{'Tags'}};

    ## Main Match Loop
    if()
    {
      foreach my $tag (@tags_l)
      {
        print $tag."\n";
        my $count = amatch($tag,["i"], @tags_f);
        $matches+=$count;
      }
    }
  }
}
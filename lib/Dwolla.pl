#!/usr/bin/perl
use strict;
use warnings;

use WebService::Dwolla; # Include Dwolla REST API Client
use Data::Dumper;     # Include this to help with debugging.

my $key    = 'Jwj1SCxTtuUl4TgqwwkCZMZr0Olqm1k7aJ+TGpZSx25YYMxH78';
my $secret = 'Cf7XFcqol/86YGd1DC8GbEcsySgWiCFt/n499zULopwa5FezC9';
my $redirect_url = 'http://mysterious-stream-6921.herokuapp.com/auth';

my $api = WebService::Dwolla->new($key,$secret,$redirect_url,['send']);

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  PREREQ_PM => {'Mojolicious' => '4.11'},
  PREREQ_PM => {'MongoDB' => '.702'},
  PREREQ_PM => {'String::Approx' => '3.26'},
  PREREQ_PM => {'WebService::Dwolla' => '.05'},
);

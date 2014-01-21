#! /usr/bin/perl

use WebService::Dwolla;
use CGI;

my $key    = 'Jwj1SCxTtuUl4TgqwwkCZMZr0Olqm1k7aJ+TGpZSx25YYMxH78';
my $secret = 'Cf7XFcqol/86YGd1DC8GbEcsySgWiCFt/n499zULopwa5FezC9';
my $redirect_url = 'http://mysterious-stream-6921.herokuapp.com/auth';

my $api = WebService::Dwolla->new($key,$secret,$redirect_url,['send']);

my $q = new CGI->new;
my $params = $q->Vars;

# Step 1: Create an authentication URL that the user will be redirected to,
if (!$params->{'code'} || !$params->{'error'}) {
    print $q->redirect($api->get_auth_url());
}

# Exchange the temporary code given to us in the querystring, for
# a never-expiring OAuth access token.
if ($params->{'error'}) {
    $q->p('There was an error. Dwolla said: ' . $params->{'error_description'});
} elsif ($params->{'code'}) {
    $api->request_token($code);
    if (!$token) {
        my @e = $api->get_errors();
    } else {
        $q->p('Your token is: ' . $params->{'code'});
    }
}

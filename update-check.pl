#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use FindBin 1.51 qw( $RealBin );        # To find the directory the script is located in, even if it is run as a packed executable
use Config::Tiny;                       # So we don't have to store anything in this file
use Getopt::Long;                       # For passing command line arguments
use DateTime;                           # For timestamping output
use Mojo::UserAgent;                    # Get the updates page
use Mojo::DOM;                          # Parse the page 
use Mojo::IOLoop;                       # Do this on a loop
use JSON::Parse 'json_file_to_perl';    # Read the autoupdate config file in the DCS root dir

########## Command Line Arguments ##########

my $config_file = "$RealBin/config.ini";
my $kill_timer = 0;

GetOptions ("config=s" => \$config_file,
            "kill_timer:i" => \$kill_timer,
) or die ("Error in command line args\n");


########## Load and Validate Configuration ##########

my $config = Config::Tiny->new;
die curr_time() . " - Cannot find 'config.ini'"
unless -f $config_file;

$config = Config::Tiny->read( $config_file, 'utf8' );
say curr_time() . ' - Loaded Config';

my $autoupdate_file = $config->{'game'}{'install_dir'} . 'autoupdate.cfg';
die curr_time() . " - Cannot find 'autoupdate.cfg'. Please check your config and try again."
unless -f $autoupdate_file;

my $update_interval = $config->{'updates'}{'interval'}; # In seconds
die curr_time() . " - Invalid update interval, must be an integer between 60 and 600 seconds"
unless $update_interval =~ /^\d+$/ and $update_interval >= 60 and $update_interval <= 600;

my $discord_username = $config->{'discord'}{'discord_username'};
my $discord_avatar_url = $config->{'discord'}{'avatar_url'};

########## Set up UserAgent ##########

my $update_url = 'https://updates.digitalcombatsimulator.com';
my $changelog_url = 'https://www.digitalcombatsimulator.com/en/news/changelog';
my $ua = Mojo::UserAgent->new();
$ua->transactor->name($config->{'updates'}{'user_agent'});

########## Get Current DCS Version ##########

my $json = json_file_to_perl($autoupdate_file);
my $client_branch = $json->{'branch'};
my $client_version = $json->{'version'};
die "Could not read find Branch and Version information in autoupdate file"
unless $client_branch and $client_version and $client_branch =~ /^(openbeta|stable)$/ and $client_version =~ /^(\d+\.?)+$/;


########## Begin ##########

say curr_time() . " - Current DCS Version: $client_branch $client_version";
say curr_time() . " - Checking for updates every ~$update_interval seconds - Press Ctrl+C to stop.";

# Check for updates one second from now.
Mojo::IOLoop->timer(1 => sub { check_for_updates(); });

# Used for PAR::Packer so it can run the application temporarily to gather dependencies.
Mojo::IOLoop->timer($kill_timer => sub { Mojo::IOLoop->reset; }) if $kill_timer > 0;

# Start the IOLoop.
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;


########## Subroutines ##########

# Get current time in Hours:Minutes:Seconds for timestamp printing. Don't need the date.
sub curr_time
{
    my $dt = DateTime->now;
    $dt->set_time_zone('local');
    return $dt->hms;
}

# Offset the specified delay by +/- 30 seconds to seem a little bit less robotic.
sub fuzzy_delay
{
    my $rand = int(rand(60)) - 30;
    return $update_interval + $rand;
}

# Returns the latest version matching the currently installed branch
sub latest_version
{
    my $tx = $ua->get($update_url);
    my $dom = $tx->res->dom;

    foreach my $link ( $dom->find('a[href^="' . $changelog_url . '/' . $client_branch . '"]')->each ) { return $link->text;}
    return "Version Not Found";

}

# Compares the latest version on the website with the currently installed version
# Takes action based on the result.
sub check_for_updates
{
    my $latest_version = latest_version();
    if ( $client_version eq $latest_version ) 
    {
        my $content = "You are on the latest version";
        say curr_time() . ' - ' . $content;
        Mojo::IOLoop->timer(fuzzy_delay() => sub { check_for_updates() });
    }
    else
    {
        my $content = "New Version Detected. Update Available: $client_branch $latest_version";
        say curr_time() . ' - ' . $content . "\a";
        post_to_discord($content);
        Mojo::IOLoop->reset;
    }
}

# Send a message to Discord via Webhook
# Accepts the content to send as a string
# Avatar and Username are configured in config.ini
sub post_to_discord
{
    my $content = shift;

    # Ping the user if configured with their Discord ID
    my $user_id = $config->{'discord'}{'user_id'};
    if ( $user_id =~ /^\d+$/ ) { $content = '<@' . $user_id . '> ' . $content; }

    # Fill out the required payload fields
    my $payload = {
        'content' => $content,
        'username' => $discord_username,
        'avatar_url' => $discord_avatar_url,
    };

    my $webhook_url = $config->{'discord'}{'webhook_url'};
    if ( $webhook_url )
    {
        say curr_time() . " - Posting to Discord";
        say $content;
        $ua->post($webhook_url => json => $payload);
    }
}

=pod

=head1 DCS Update Checker

This is a pretty simple script which just polls the DCS Updates page (https://updates.digitalcombatsimulator.com) periodically and compares the latest version on that page with the version listed in your game's autoupdate.cfg file.

If they do not match it will ding the terminal and optionall post a message to a Discord webhook URL and then exit. Otherwise it will keep checking every few minutes (configurable).

=head2 Config

Rename "config.ini.example" to "config.ini" and then fill it out as instructed inside the file. Use your favorite text editor.

=head2 Run from source

You will need Perl and Cpanminus installed. Run `cpanm --installdeps .` to install this script's dependencies, and then `perl update-check.pl` to start the script.

=head2 Run from .exe

Just double click the .exe file after filling out the config.

=head2 Build from source

```bash
cpanm --installdeps --dev .
make
```

=head2 Contribute

Github Issues Tab

=head2 LICENSE

MIT

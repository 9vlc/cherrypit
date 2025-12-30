# moved to codeberg: https://codeberg.org/9vlc/cherrypit

# cherrypit
this is a simple web tarpit made in shell script, designed to waste the resources of
automatic vulnerability search bots, ai scrapers, etc.

# how to use
you need a cgi compatible httpd. this script must be modified with correct paths for the data files
(preferably outside the site root), set as the 404 handler, then response body streaming must be enabled in your httpd.

## dependencies
- shell
- awk
- coreutils
  - tr
  - [jot](https://man.freebsd.org/cgi/man.cgi?jot%281%29) or od
  - sleep
  - printf

# test it out
run `curl https://paidbsd.org/.env` or go to https://paidbsd.org/boaform/admin.php and enjoy the slooow ride.

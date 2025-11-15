#!/bin/sh
# by 9vlc
set -eu

# max boundary for random sleep
pit_sleep_fmax=30

# data directories
pit_copyrights='data/copyrights'
pit_tags='data/tags'
pit_props='data/props'
pit_vars='data/vars'
pit_text='data/text'

# all files must be readable
[ -r "$pit_copyrights" ] || exit 1
[ -r "$pit_tags" ] || exit 1
[ -r "$pit_props" ] || exit 1

#
# return a random number
#
pit_rand()
{
	if command -v jot >/dev/null; then
		jot -s '' -r 4
	elif [ -r /dev/random ] && ! [ -f /dev/random ]; then
		if ! command -v od >/dev/null; then
			>&2 echo "od and jot commands not available, no way to open the rng source. exiting."
			exit 1
		fi
		echo $((od -An -tu4 -N4 /dev/random))
	else
		>&2 echo "no /dev/random and jot command is not available, exiting"
		exit 1
	fi
}

#
# sleep for a random amount of time
#
pit_sleep()
{
	sleep $(($(pit_rand) % pit_sleep_fmax)).$(pit_rand)
}

#
# print a random line of a file
#
pit_rand_line()
{
	local lines="$(cat "$1")"
	local line_count="$(printf '%s\n' "$lines" | grep -c '^')"
	local rand_index="$(($(pit_rand) % line_count + 1))"
	printf '%s\n' "$lines" | awk -v idx="$rand_index" '
		NR == idx {
			str = $0
			while (match(str, /\{![^{][^!]*!\}/)) {
				start = substr(str, 1, RSTART - 1)
				mid = substr(str, RSTART + 2, RLENGTH - 4)
				end = substr(str, RSTART + RLENGTH)

				new_str = start
				while((mid | getline line) > 0) {
					new_str = new_str line
				}
				close(mid)
				str = new_str end
			}
			print str
		}
	'
}

pit_main()
{
	if [ "$content" = 'text/html' ]; then
		pit_sleep
		# start
		echo '<!doctype html>'
		printf '<html>'
		# maybe print a random copyright
		[ $(($(pit_rand) % 2)) = 1 ] && pit_rand_line "$pit_copyrights"
		pit_sleep

		echo '<head>'
		echo '<meta http-equiv="Content-Type" content="text/html" charset="utf-8">'
		pit_sleep
		echo '</head><body>'
		while :; do
			printf '<%s%s>' \
				"$(pit_rand_line "$pit_tags")" \
				"$([ $(($(pit_rand) % 4)) = 1 ] && printf ' ' && pit_rand_line "$pit_props")"
			[ $(($(pit_rand) % 2)) = 1 ] && echo
			pit_sleep
			pit_rand_line "$pit_text"
		done
	elif [ "$content" = 'text/plain' ]; then
		while :; do
			pit_sleep
			pit_rand_line "$pit_vars"
		done
	else
		echo "Not implemented"
	fi
}

# check
scraper=0
case "${REQUEST_URI:-}" in
	# scraper is searching for dotfiles and env
	*.env*|aws/)
		scraper=1
		content=text/plain
	;;
	# things that would expect an html page like a router login
	*.php|boaform|cgi-bin)
		scraper=1
		content=text/html
	;;
esac

if [ $scraper = 1 ]; then
	# if it's a possible scraper, we welcome it with warm hands
	echo "Status: 200 OK"
	echo "Content-type: $content"
	echo ""
	pit_main "$content"
else
	# normal users get a 404
	echo "Status: 404 Not Found"
	echo "Content-type: text/plain"
	echo ""
	echo "The file you're searching for does not exist."
fi

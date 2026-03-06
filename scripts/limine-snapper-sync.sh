#!/usr/bin/env bash

readonly SCRIPT_NAME="limine-snapper-sync"
readonly RESTORE_LOCKFILE="/tmp/limine-snapper-restore.lock"
readonly LIMINE_LOCK_FILE="/tmp/limine-global.lock"

_color_reset=""
_color_yellow=""
_color_red=""
colors="$(tput colors 2>/dev/null || echo 0)"
if ((colors >= 8)); then
	_color_reset="\033[0m"
	_color_yellow="\033[1;33m"
	_color_red="\033[1;31m"
fi

warning_msg() {
	echo -e "${_color_yellow}WARNING: $1${_color_reset} ${2:-}" >&2
}

error_msg() {
	echo -e "${_color_red}ERROR: $1${_color_reset} ${2:-}" >&2
}

### Check if the script is being run with root privileges
if [ "$EUID" -ne 0 ]; then
	error_msg "${SCRIPT_NAME} must be run with root privileges."
	exit 1
fi

mutex_lock() {
	local name=$1
	exec 200>${LIMINE_LOCK_FILE} || {
		rm -f ${LIMINE_LOCK_FILE}
		exec 200>${LIMINE_LOCK_FILE}
	}
	flock --timeout=30 200 || {
		warning_msg "Mutex lock timeout on ${name}."
		return 1
	}
}

mutex_unlock() {
	flock --unlock 200
}

# Debounce multiple concurrent requests.
# Only the first caller becomes owner and waits until no new request, then it proceeds.
# All other callers only refresh the lock-timestamp and should exit immediately.
# This improves performance by grouping many snapshot deletions into one sync instead of running many syncs.
debounce_request_lock() {
	local debounce_ms=800 # debounce window in milliseconds
	local lock="/dev/shm/limine-snapper-debounce.lock"
	local now_ms last_update lock_age

	# Ensure the lock file exists
	: >"$lock"

	# Open lock file descriptor and try to become owner
	exec {fd}>"$lock" || return 1
	if flock -n "$fd"; then
		# The first caller becomes owner
		while :; do
			# Poll interval
			sleep 0.2
			now_ms=$(date +%s%3N)
			# Read last timestamp of the lock file
			if ! last_update=$(date -r "$lock" +%s%3N 2>/dev/null); then
				# Reading timestamp failed -> stop waiting and proceed
				flock -u "$fd"
				rm -f "$lock"
				return 0
			fi
			lock_age=$((now_ms - last_update))
			# If no updates arrived within debounce window -> proceed
			if ((lock_age > debounce_ms)); then
				# release lock
				flock -u "$fd"
				rm -f "$lock"
				return 0
			fi
		done
	else
		# Other callers are not owner -> refresh timestamp and exit
		: >"$lock"
		return 1
	fi
}

# Main logic
if [ -e "${RESTORE_LOCKFILE}" ]; then
	warning_msg "limine-snapper-restore is already running."
	exit 1
fi

for arg in "$@"; do
	if [[ "$arg" == "--debounce" ]]; then
		debounce_request_lock || exit 0
	fi
done

mutex_lock "${SCRIPT_NAME}"
/usr/lib/limine/limine-snapper-sync "$@"
exit_code="$?"
mutex_unlock

exit "$exit_code"

#!/usr/bin/env bash
#
# entrypoint.sh: The entry-point run within the container to run user commands.
#
# Sets up the environment in which the user's command will run, then uses `gosu`
# to run it under the correct UID/GID.
#

set -e
# set -x

# If no command to run specified, just quit.
[[ $# == 0 ]] && exit 0

[[ "$WORK_GID" == 0 ]] && unset WORK_GID
[[ "$WORK_UID" == 0 ]] && unset WORK_UID

# Adjust `stack` user's UID/GID to match that of the user on the host OS.
# Since we don't know the UID/GID ahead of time, this cannot be done when
# creating the image.  If we don't do this, any files created by the user's
# commands in the bind-mounted work directory will be owned by an incorrect UID
# instead of the user running the commands.

# Use a horrendous trick to figure out which UID to use, since boot2docker introduces another layer of
# UID redirection and whatever stack passes in will probably be wrong
WORK_UID="$(stat -c %u "$WORK_HOME/.cabal")"
WORK_GID="$(stat -c %g "$WORK_HOME/.cabal")"

if [[ -n "$WORK_UID" ]]; then
    usermod -o --uid "$WORK_UID" stack # >/dev/null 2>&1
    [[ -n "$WORK_GID" ]] && groupmod -o --gid "$WORK_GID" stack >/dev/null 2>&1
    INIT_USER=stack
else
    INIT_USER=root
fi

if [[ -n "$WORK_HOME" ]]; then

    # Copy "skeleton" to volume-mounted home directory.
    if [[ ! -f "$WORK_HOME/.bashrc" ]]; then
        (cd /home/_stack; tar cf - --exclude .stack --exclude .cabal .) \
            |gosu $INIT_USER tar xkf - -C "$WORK_HOME"
        find "$WORK_HOME" \( \( -name .stack -o -name .cabal -o -name .local \) -prune \) -o \( -type f -print0 \) |xargs -0 sed -i "s@/home/_stack/@$WORK_HOME/@"
    fi

    # Create the sandbox's cabal configuration if it does not yet exist.
    if [[ ! -f "$WORK_HOME/.cabal/config" && -d /home/_stack/.cabal ]]; then
        (cd /home/_stack/.cabal; tar cf - .) |gosu $INIT_USER tar xkf - -C "$WORK_HOME/.cabal"
        find "$WORK_HOME/.cabal" -type f -print0 |xargs -0 sed -i "s@/home/_stack/@$WORK_HOME/@"
    fi

    # Initialize stack root with package index and build plan, if newer.
    if [[ -e "$WORK_HOME/.stack" ]]; then
        if [[ /home/_stack/.stack/indices/Hackage/00-index.tar -nt "$WORK_HOME/.stack/indices/Hackage/00-index.tar" ]]; then
            gosu $INIT_USER mkdir -p "$WORK_HOME/.stack/indices/Hackage/"
            gosu $INIT_USER cp /home/_stack/.stack/indices/Hackage/00-index.{tar,cache} \
               "$WORK_HOME/.stack/indices/Hackage/"
        fi
        for plan in $(find /home/_stack/.stack/build-plan -maxdepth 1 -name '*.yaml'); do
            if [[ ! -e "$WORK_HOME/.stack/build-plan/$(basename $plan)" ]]; then
                gosu $INIT_USER mkdir -p "$WORK_HOME/.stack/build-plan"
                gosu $INIT_USER cp "$plan" "$WORK_HOME/.stack/build-plan/$(basename $plan)"
            fi
        done
    fi

    # Change user's home directory.
    sed -i "/^$INIT_USER:/ "'s@\(.*:\)[^:]*\(:[^:]*\)$@\1'"$WORK_HOME"'\2@' /etc/passwd

    # Adjust PATH.
    export PATH="$WORK_HOME/bin:$WORK_HOME/.local/bin:$PATH"
    [[ -d "$WORK_HOME/.cabal" ]] && export PATH="$WORK_HOME/.cabal/bin:$PATH"
else
    if [[ -n "$WORK_UID" ]]; then
        find /home/_stack -print0 |xargs -0 chown "${WORK_UID}:${WORK_GID:-0}"
    fi
fi

# Works around package caches being reported as out-of-date even though they're not.
touch $(dirname "$(which ghc)")/../lib/*/package.conf.d/package.cache \
      $(dirname "$(which ghcjs)")/../lib/*/*/package.conf.d/package.cache \
      2>/dev/null \
      || true

[[ -n "$WORK_WD" ]] && cd "$WORK_WD"

# Use `gosu` to run the user's command as the correct UID/GID.
exec /sbin/my_init $MY_INIT_ARGS -- gosu "$INIT_USER" "$@"
# exec /sbin/my_init $MY_INIT_ARGS -- sudo -EHu "$INIT_USER" PATH="$PATH" /usr/bin/env -- "$@"

#!/usr/bin/env sh

if [ $# -lt 3 ] || [ $# -gt 4 ]; then
    cat >&2 <<EOF
Python WSGI application runner, using gunicorn with a Unix socket.

Usage: $0 <app> <root> <socket> [prefix]

  app: Python path to the WSGI app, the entrypoint into your code.

    The application name is of the form 'module.path:variable_name'.

    With Flask, the main Flask() object is itself the application.
    For example, if a Flask project contains 'app = Flask()' in the
    script service.py, then you would use 'service:app' here.

    With Django, the default project defines an application in wsgi.py.
    For a default project called 'service', you would have
    'service.wsgi:application' as your app's entrypoint.

  root: Project directory, containing your application.

    gunicorn should be able to import your app from this directory.

  socket: Path to create the server socket file.

    You don't need to create this file beforehand (though the parent
    directory does need to exist).

    Apache will be configured to send requests to, and retrieve
    responses from, this socket.

  prefix: Optional URL path prefix.

    If you are presenting your app to end-users in a subdirectory of a
    larger site, set the path to the URL root of your app here.

    Start with a slash, but omit the trailing slash, e.g. '/service'.

    This will set 'SCRIPT_NAME' for your app to the desired prefix.
    Django and Flask will make use of this automatically.

This script is part of the Sample SRCF Setups group account.
Please report any bugs to sample-admins@srcf.net.
EOF
    exit 1
fi

app="$1"
root="$2"
socket="$3"

cat <<EOF
---
gunicorn: $(which gunicorn)
app: $app ($(realpath "$root"))
socket: $(realpath "$socket")
---
EOF

if [ ! -z "$4" ]; then
    export SCRIPT_NAME="$4"
fi

# Change directory to the project root, relative to this script.
# This means you don't need to be in the directory yourself to run it.

cd "$(dirname $(realpath "$0"))"
cd "$root"

# Options applied to gunicorn:
#
# - reload: Watch for code changes and restart the app as needed.
# - access-logfile: Log HTTP requests received by the app.
# - access-logformat: Use X-Forwarded-For for end-user access IPs.
# - error-logfile: Log error messages from gunicorn and its workers.
# - bind: Expose the app on a Unix socket.
#
# Other useful options if you have a newer version of gunicorn:
#
# - capture-output: Print app output and tracebacks.
#
# Documentation: https://docs.gunicorn.org/en/stable/settings.html

logfmt='%({x-forwarded-for}i)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s"'

exec gunicorn \
  --access-logfile - \
  --access-logformat "$logfmt" \
  --error-logfile - \
  --bind "unix:$socket" \
  "$app"

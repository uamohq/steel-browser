#!/bin/sh

# Check for --no-nginx flag
START_NGINX=true
for arg in "$@"; do
    if [ "$arg" = "--no-nginx" ]; then
        START_NGINX=false
        break
    fi
done

if $START_NGINX; then
    echo "Starting nginx..."
    nginx -c /app/nginx.conf
    # Check if nginx started successfully
    if ! ps aux | grep nginx | grep -v grep > /dev/null; then
        echo "Failed to start nginx"
        exit 1
    fi
else
    echo "Skipping nginx startup..."
fi

### Clean up stale lock files
echo "Cleaning up stale lock files..."
rm -f /run/dbus/pid /tmp/.X10-lock

# Create dbus directory and start daemon
echo "Starting dbus..."
mkdir -p /var/run/dbus
dbus-daemon --system --fork

# Check if Xvfb is already running
if ! pgrep -x "Xvfb" > /dev/null
then
    echo "Starting Xvfb..."
    Xvfb :99 -screen 0 1280x720x24 -ac &
else
    echo "Xvfb is already running."
fi

# Set the DISPLAY environment variable
export DISPLAY=:99

# Set the CDP_REDIRECT_PORT environment variable
export CDP_REDIRECT_PORT=9223
export HOST=0.0.0.0

# Start X11VNC (VNC server)
echo "Starting X11VNC..."
x11vnc -display :99 -forever -shared -nopw -rfbport 5900 &

# Start noVNC (web-based VNC viewer)
echo "Starting noVNC..."
websockify --web=/usr/share/novnc/ 6080 localhost:5900 &

# Run the `npm run start` command but without npm.
# NPM will introduce its own signal handling
# which will prevent the container from waiting
# for a session to be released before stopping gracefully
exec node ./build/index.js
#!/bin/bash
# Simple web server for PHP 8.3 Extension Manager UI
# Uses PHP's built-in web server

# UI directory is in package/ui
WEB_ROOT="/var/packages/php83/target/package/ui"
PHP_BIN="/var/packages/php83/target/package/bin/php"
PID_FILE="/var/packages/php83/var/webserver.pid"
LOG_FILE="/var/packages/php83/var/log/webserver.log"
PORT_FILE="/var/packages/php83/target/package/etc/webserver.port"

# Default port (will be configurable during install)
DEFAULT_PORT=8380

# Get configured port or use default
if [ -f "$PORT_FILE" ]; then
    WEB_PORT=$(cat "$PORT_FILE")
else
    WEB_PORT=$DEFAULT_PORT
fi

start_server() {
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo "Web server already running on port $WEB_PORT"
        return 0
    fi

    echo "Starting PHP Extension Manager web server on port $WEB_PORT..."

    cd "$WEB_ROOT"
    "$PHP_BIN" -S "0.0.0.0:$WEB_PORT" \
        -t "$WEB_ROOT" \
        >> "$LOG_FILE" 2>&1 &

    echo $! > "$PID_FILE"

    # Wait a bit and check if it started
    sleep 2
    if kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo "Web server started successfully on port $WEB_PORT"
        echo "Access at: http://$(hostname):$WEB_PORT/"
        return 0
    else
        echo "Failed to start web server"
        rm -f "$PID_FILE"
        return 1
    fi
}

stop_server() {
    if [ ! -f "$PID_FILE" ]; then
        echo "Web server not running"
        return 0
    fi

    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "Stopping web server (PID: $PID)..."
        kill "$PID"
        sleep 2

        # Force kill if still running
        if kill -0 "$PID" 2>/dev/null; then
            kill -9 "$PID"
        fi
    fi

    rm -f "$PID_FILE"
    echo "Web server stopped"
}

status_server() {
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo "Web server is running on port $WEB_PORT (PID: $(cat "$PID_FILE"))"
        return 0
    else
        echo "Web server is not running"
        return 1
    fi
}

case "$1" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    status)
        status_server
        ;;
    restart)
        stop_server
        sleep 1
        start_server
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac

exit $?

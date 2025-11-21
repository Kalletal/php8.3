#!/usr/bin/env bash
# Monitor PHP compilation progress

LOG_FILE="/tmp/php-final-build.log"
BUILD_PID=1514122

echo "======================================"
echo "PHP 8.3.8 Compilation Monitor"
echo "======================================"
echo ""

# Check if build is still running
if ps -p $BUILD_PID > /dev/null 2>&1; then
    echo "✓ Build process is RUNNING (PID: $BUILD_PID)"
else
    echo "✗ Build process has FINISHED or STOPPED"
fi

echo ""
echo "Current status:"
echo "---------------"

# Show last 30 lines of log
tail -30 "$LOG_FILE"

echo ""
echo "======================================"
echo "Progress indicators:"
echo "======================================"

# Count completed steps
echo "Dependencies built:"
grep -c "===>.*Compiling for" "$LOG_FILE" 2>/dev/null || echo "0"

echo ""
echo "To monitor in real-time:"
echo "  tail -f $LOG_FILE"
echo ""
echo "To check if still running:"
echo "  ps -p $BUILD_PID"

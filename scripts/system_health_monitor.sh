#!/bin/bash

# System Health Monitor Script
# Monitors CPU, Memory, Disk usage and logs alerts

LOG_FILE="/var/log/system_health.log"
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEMORY=80
ALERT_THRESHOLD_DISK=80

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to check CPU usage
check_cpu() {
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    cpu_usage=${cpu_usage%.*}

    if [ "$cpu_usage" -gt "$ALERT_THRESHOLD_CPU" ]; then
        log_message "ALERT: High CPU usage detected: ${cpu_usage}%"
        return 1
    else
        log_message "INFO: CPU usage is normal: ${cpu_usage}%"
        return 0
    fi
}

# Function to check memory usage
check_memory() {
    memory_usage=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')

    if [ "$memory_usage" -gt "$ALERT_THRESHOLD_MEMORY" ]; then
        log_message "ALERT: High memory usage detected: ${memory_usage}%"
        return 1
    else
        log_message "INFO: Memory usage is normal: ${memory_usage}%"
        return 0
    fi
}

# Function to check disk usage
check_disk() {
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

    if [ "$disk_usage" -gt "$ALERT_THRESHOLD_DISK" ]; then
        log_message "ALERT: High disk usage detected: ${disk_usage}%"
        return 1
    else
        log_message "INFO: Disk usage is normal: ${disk_usage}%"
        return 0
    fi
}

# Function to check service status
check_service_status() {
    service_name="wisecow"
    if systemctl is-active --quiet "$service_name"; then
        log_message "INFO: Service $service_name is running"
        return 0
    else
        log_message "ALERT: Service $service_name is not running"
        return 1
    fi
}

# Function to check network connectivity
check_network() {
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_message "INFO: Network connectivity is working"
        return 0
    else
        log_message "ALERT: Network connectivity issues detected"
        return 1
    fi
}

# Main monitoring loop
main() {
    log_message "Starting system health monitoring..."

    while true; do
        log_message "=== Health Check Started ==="

        check_cpu
        check_memory
        check_disk
        check_service_status
        check_network

        log_message "=== Health Check Completed ==="
        echo ""

        # Wait for 60 seconds before next check
        sleep 60
    done
}

# Handle script termination
trap 'log_message "System health monitoring stopped"; exit 0' SIGINT SIGTERM

# Start monitoring if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
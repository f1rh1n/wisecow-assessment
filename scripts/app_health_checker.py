#!/usr/bin/env python3

"""
Application Health Checker
Monitors the Wisecow application health and sends alerts
"""

import requests
import time
import logging
import sys
import json
from datetime import datetime
from typing import Optional, Dict, Any

# Configuration
APP_URL = "http://localhost:4499"
CHECK_INTERVAL = 30  # seconds
TIMEOUT = 10  # seconds
MAX_RETRIES = 3
LOG_FILE = "/var/log/app_health.log"

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)

class HealthChecker:
    def __init__(self, url: str = APP_URL):
        self.url = url
        self.consecutive_failures = 0
        self.last_success = None
        self.last_failure = None

    def check_http_health(self) -> Dict[str, Any]:
        """
        Check HTTP health of the application
        Returns health status with metrics
        """
        try:
            start_time = time.time()
            response = requests.get(self.url, timeout=TIMEOUT)
            response_time = (time.time() - start_time) * 1000  # ms

            health_data = {
                'status': 'healthy' if response.status_code == 200 else 'unhealthy',
                'status_code': response.status_code,
                'response_time_ms': round(response_time, 2),
                'timestamp': datetime.now().isoformat(),
                'content_length': len(response.content) if response.content else 0
            }

            if response.status_code == 200:
                self.consecutive_failures = 0
                self.last_success = datetime.now()
                logger.info(f"Health check passed - Response time: {response_time:.2f}ms")
            else:
                self.consecutive_failures += 1
                self.last_failure = datetime.now()
                logger.warning(f"Health check failed - Status code: {response.status_code}")

            return health_data

        except requests.exceptions.RequestException as e:
            self.consecutive_failures += 1
            self.last_failure = datetime.now()

            health_data = {
                'status': 'unhealthy',
                'error': str(e),
                'timestamp': datetime.now().isoformat(),
                'consecutive_failures': self.consecutive_failures
            }

            logger.error(f"Health check failed - Connection error: {e}")
            return health_data

    def check_application_metrics(self) -> Dict[str, Any]:
        """
        Check application-specific metrics
        """
        try:
            # Check if the response contains expected content
            response = requests.get(self.url, timeout=TIMEOUT)

            metrics = {
                'contains_cow': 'cowsay' in response.text.lower() if response.text else False,
                'contains_fortune': 'fortune' in response.text.lower() if response.text else False,
                'html_valid': response.text.startswith('<!DOCTYPE html>') if response.text else False,
                'content_size': len(response.content) if response.content else 0
            }

            return metrics

        except Exception as e:
            logger.error(f"Failed to check application metrics: {e}")
            return {'error': str(e)}

    def send_alert(self, health_data: Dict[str, Any]) -> None:
        """
        Send alert when application is unhealthy
        """
        if self.consecutive_failures >= 3:
            alert_message = (
                f"CRITICAL: Wisecow application is unhealthy!\n"
                f"Consecutive failures: {self.consecutive_failures}\n"
                f"Last failure: {self.last_failure}\n"
                f"Error details: {health_data.get('error', 'Unknown error')}"
            )

            logger.critical(alert_message)

            # Here you could integrate with alerting systems like:
            # - Slack webhook
            # - Email notifications
            # - PagerDuty
            # - Discord webhook
            # etc.

    def run_health_check(self) -> None:
        """
        Run a single health check cycle
        """
        logger.info("Starting health check...")

        # Basic HTTP health check
        health_data = self.check_http_health()

        # Application-specific metrics
        if health_data['status'] == 'healthy':
            metrics = self.check_application_metrics()
            health_data['metrics'] = metrics

        # Send alert if unhealthy
        if health_data['status'] == 'unhealthy':
            self.send_alert(health_data)

        # Log health summary
        logger.info(f"Health status: {health_data['status']}")

        return health_data

    def monitor(self) -> None:
        """
        Continuous monitoring loop
        """
        logger.info(f"Starting continuous health monitoring for {self.url}")
        logger.info(f"Check interval: {CHECK_INTERVAL} seconds")

        try:
            while True:
                self.run_health_check()
                time.sleep(CHECK_INTERVAL)

        except KeyboardInterrupt:
            logger.info("Health monitoring stopped by user")
        except Exception as e:
            logger.error(f"Health monitoring failed: {e}")
            raise

def main():
    """
    Main function to run the health checker
    """
    import argparse

    parser = argparse.ArgumentParser(description='Wisecow Application Health Checker')
    parser.add_argument('--url', default=APP_URL, help='Application URL to check')
    parser.add_argument('--interval', type=int, default=30, help='Check interval in seconds')
    parser.add_argument('--once', action='store_true', help='Run health check once and exit')

    args = parser.parse_args()

    # Override global configuration
    global CHECK_INTERVAL
    CHECK_INTERVAL = args.interval

    # Create health checker instance
    checker = HealthChecker(args.url)

    if args.once:
        # Run health check once
        result = checker.run_health_check()
        print(json.dumps(result, indent=2))
    else:
        # Start continuous monitoring
        checker.monitor()

if __name__ == "__main__":
    main()
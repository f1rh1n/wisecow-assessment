#!/bin/bash

# Wisecow Deployment Test Script
# Comprehensive testing of the Wisecow application deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="wisecow"
APP_NAME="wisecow"
SERVICE_NAME="wisecow-service"
DEPLOYMENT_NAME="wisecow-deployment"
INGRESS_NAME="wisecow-ingress"
TEST_TIMEOUT=300
LOCAL_PORT=8080

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Test result functions
test_passed() {
    ((TESTS_PASSED++))
    ((TOTAL_TESTS++))
    echo -e "${GREEN}✓ PASS:${NC} $1"
}

test_failed() {
    ((TESTS_FAILED++))
    ((TOTAL_TESTS++))
    echo -e "${RED}✗ FAIL:${NC} $1"
}

test_skipped() {
    echo -e "${YELLOW}⚠ SKIP:${NC} $1"
}

# Check if namespace exists
test_namespace() {
    log "Testing namespace existence..."

    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        test_passed "Namespace '$NAMESPACE' exists"
    else
        test_failed "Namespace '$NAMESPACE' does not exist"
        return 1
    fi
}

# Test deployment status
test_deployment() {
    log "Testing deployment status..."

    # Check if deployment exists
    if ! kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" &> /dev/null; then
        test_failed "Deployment '$DEPLOYMENT_NAME' does not exist"
        return 1
    fi

    # Check deployment status
    local ready_replicas=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
    local desired_replicas=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')

    if [[ "$ready_replicas" == "$desired_replicas" && "$ready_replicas" -gt 0 ]]; then
        test_passed "Deployment has $ready_replicas/$desired_replicas replicas ready"
    else
        test_failed "Deployment not ready: $ready_replicas/$desired_replicas replicas"
    fi

    # Check deployment conditions
    local available=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Available")].status}')
    if [[ "$available" == "True" ]]; then
        test_passed "Deployment condition: Available"
    else
        test_failed "Deployment condition: Not Available"
    fi
}

# Test pods status
test_pods() {
    log "Testing pods status..."

    local pods=$(kubectl get pods -l app="$APP_NAME" -n "$NAMESPACE" --no-headers)
    local pod_count=$(echo "$pods" | wc -l)

    if [[ $pod_count -eq 0 ]]; then
        test_failed "No pods found for app '$APP_NAME'"
        return 1
    fi

    test_passed "Found $pod_count pod(s) for app '$APP_NAME'"

    # Check each pod status
    while read -r pod_line; do
        if [[ -n "$pod_line" ]]; then
            local pod_name=$(echo "$pod_line" | awk '{print $1}')
            local pod_status=$(echo "$pod_line" | awk '{print $3}')

            if [[ "$pod_status" == "Running" ]]; then
                test_passed "Pod '$pod_name' is Running"
            else
                test_failed "Pod '$pod_name' status: $pod_status"
            fi
        fi
    done <<< "$pods"
}

# Test service
test_service() {
    log "Testing service..."

    if ! kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" &> /dev/null; then
        test_failed "Service '$SERVICE_NAME' does not exist"
        return 1
    fi

    # Check service endpoints
    local endpoints=$(kubectl get endpoints "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.subsets[*].addresses[*].ip}')
    if [[ -n "$endpoints" ]]; then
        local endpoint_count=$(echo "$endpoints" | wc -w)
        test_passed "Service has $endpoint_count endpoint(s)"
    else
        test_failed "Service has no endpoints"
    fi

    # Check service ports
    local service_port=$(kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].port}')
    local target_port=$(kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].targetPort}')

    if [[ "$service_port" == "80" && "$target_port" == "4499" ]]; then
        test_passed "Service port configuration correct (80 -> 4499)"
    else
        test_failed "Service port configuration incorrect ($service_port -> $target_port)"
    fi
}

# Test ingress
test_ingress() {
    log "Testing ingress..."

    if ! kubectl get ingress "$INGRESS_NAME" -n "$NAMESPACE" &> /dev/null; then
        test_failed "Ingress '$INGRESS_NAME' does not exist"
        return 1
    fi

    # Check ingress backend
    local backend_service=$(kubectl get ingress "$INGRESS_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}')
    if [[ "$backend_service" == "$SERVICE_NAME" ]]; then
        test_passed "Ingress backend service configured correctly"
    else
        test_failed "Ingress backend service misconfigured: $backend_service"
    fi
}

# Test application connectivity
test_application_connectivity() {
    log "Testing application connectivity..."

    # Start port forwarding in background
    kubectl port-forward service/"$SERVICE_NAME" "$LOCAL_PORT":80 -n "$NAMESPACE" &
    local port_forward_pid=$!

    # Wait for port forwarding to establish
    sleep 5

    # Test HTTP connectivity
    if curl -s -f "http://localhost:$LOCAL_PORT" > /dev/null; then
        test_passed "Application is accessible via port forward"

        # Test response content
        local response=$(curl -s "http://localhost:$LOCAL_PORT")
        if echo "$response" | grep -q "Wisecow"; then
            test_passed "Application response contains 'Wisecow'"
        else
            test_failed "Application response does not contain 'Wisecow'"
        fi

        if echo "$response" | grep -q "<!DOCTYPE html>"; then
            test_passed "Application returns valid HTML"
        else
            test_failed "Application does not return valid HTML"
        fi

    else
        test_failed "Application is not accessible via port forward"
    fi

    # Cleanup port forwarding
    kill $port_forward_pid 2>/dev/null || true
    wait $port_forward_pid 2>/dev/null || true
}

# Test resource limits and requests
test_resource_configuration() {
    log "Testing resource configuration..."

    local cpu_requests=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
    local memory_requests=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}')
    local cpu_limits=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}')
    local memory_limits=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')

    if [[ -n "$cpu_requests" && -n "$memory_requests" ]]; then
        test_passed "Resource requests configured (CPU: $cpu_requests, Memory: $memory_requests)"
    else
        test_failed "Resource requests not configured"
    fi

    if [[ -n "$cpu_limits" && -n "$memory_limits" ]]; then
        test_passed "Resource limits configured (CPU: $cpu_limits, Memory: $memory_limits)"
    else
        test_failed "Resource limits not configured"
    fi
}

# Test health probes
test_health_probes() {
    log "Testing health probes configuration..."

    local liveness_path=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}')
    local readiness_path=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}')

    if [[ "$liveness_path" == "/" ]]; then
        test_passed "Liveness probe configured correctly"
    else
        test_failed "Liveness probe not configured or incorrect path: $liveness_path"
    fi

    if [[ "$readiness_path" == "/" ]]; then
        test_passed "Readiness probe configured correctly"
    else
        test_failed "Readiness probe not configured or incorrect path: $readiness_path"
    fi
}

# Test security policies
test_security_policies() {
    log "Testing KubeArmor security policies..."

    # Check if KubeArmor is installed
    if ! kubectl get pods -n kubearmor &> /dev/null; then
        test_skipped "KubeArmor not installed, skipping security policy tests"
        return
    fi

    # Check if security policies exist
    local policy_count=$(kubectl get kubearmor-policies -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
    if [[ $policy_count -gt 0 ]]; then
        test_passed "Found $policy_count KubeArmor security policy(ies)"
    else
        test_failed "No KubeArmor security policies found"
    fi
}

# Test application health using health checker script
test_health_checker() {
    log "Testing application health checker..."

    if [[ ! -f "scripts/app_health_checker.py" ]]; then
        test_skipped "Health checker script not found"
        return
    fi

    # Start port forwarding for health check
    kubectl port-forward service/"$SERVICE_NAME" "$LOCAL_PORT":80 -n "$NAMESPACE" &
    local port_forward_pid=$!
    sleep 5

    # Run health checker
    if python3 scripts/app_health_checker.py --once --url "http://localhost:$LOCAL_PORT" > /dev/null 2>&1; then
        test_passed "Application health checker reports healthy"
    else
        test_failed "Application health checker reports unhealthy"
    fi

    # Cleanup
    kill $port_forward_pid 2>/dev/null || true
    wait $port_forward_pid 2>/dev/null || true
}

# Performance test
test_performance() {
    log "Testing application performance..."

    # Start port forwarding
    kubectl port-forward service/"$SERVICE_NAME" "$LOCAL_PORT":80 -n "$NAMESPACE" &
    local port_forward_pid=$!
    sleep 5

    # Simple performance test with curl
    local start_time=$(date +%s%N)
    curl -s "http://localhost:$LOCAL_PORT" > /dev/null
    local end_time=$(date +%s%N)
    local response_time=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds

    if [[ $response_time -lt 5000 ]]; then # Less than 5 seconds
        test_passed "Response time acceptable: ${response_time}ms"
    else
        test_failed "Response time too slow: ${response_time}ms"
    fi

    # Cleanup
    kill $port_forward_pid 2>/dev/null || true
    wait $port_forward_pid 2>/dev/null || true
}

# Generate test report
generate_report() {
    echo ""
    log "Test Report Generated"
    echo -e "${GREEN}==================== TEST SUMMARY ====================${NC}"
    echo -e "${GREEN}Total Tests:${NC} $TOTAL_TESTS"
    echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
    echo -e "${RED}Failed:${NC} $TESTS_FAILED"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}Overall Status: ALL TESTS PASSED ✓${NC}"
        return 0
    else
        echo -e "${RED}Overall Status: SOME TESTS FAILED ✗${NC}"
        return 1
    fi
}

# Main test execution
main() {
    log "Starting Wisecow Deployment Tests..."

    test_namespace
    test_deployment
    test_pods
    test_service
    test_ingress
    test_resource_configuration
    test_health_probes
    test_security_policies
    test_application_connectivity
    test_health_checker
    test_performance

    generate_report
}

# Handle script interruption
trap 'error "Tests interrupted by user"; exit 1' SIGINT SIGTERM

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
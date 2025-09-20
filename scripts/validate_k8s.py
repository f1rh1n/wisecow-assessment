#!/usr/bin/env python3

"""
Simple Kubernetes manifest validator
"""

import yaml
import os
import sys

def validate_k8s_manifest(filepath):
    """Validate a Kubernetes manifest file"""
    try:
        with open(filepath, 'r') as f:
            doc = yaml.safe_load(f)

        # Check required fields
        required_fields = ['apiVersion', 'kind', 'metadata']
        for field in required_fields:
            if field not in doc:
                print(f"❌ {filepath}: Missing required field '{field}'")
                return False

        # Check metadata has name
        if 'name' not in doc['metadata']:
            print(f"❌ {filepath}: Missing metadata.name")
            return False

        print(f"✅ {os.path.basename(filepath)} - Valid Kubernetes manifest")
        return True

    except Exception as e:
        print(f"❌ {filepath}: Error - {e}")
        return False

def main():
    """Main validation function"""
    manifest_dir = 'k8s-manifests'

    if not os.path.exists(manifest_dir):
        print(f"❌ Directory {manifest_dir} not found")
        sys.exit(1)

    valid_count = 0
    total_count = 0

    for filename in os.listdir(manifest_dir):
        if filename.endswith('.yaml') or filename.endswith('.yml'):
            filepath = os.path.join(manifest_dir, filename)
            total_count += 1
            if validate_k8s_manifest(filepath):
                valid_count += 1

    if valid_count == total_count:
        print(f"✅ All {total_count} Kubernetes manifests are valid")
        sys.exit(0)
    else:
        print(f"❌ {total_count - valid_count} of {total_count} manifests failed validation")
        sys.exit(1)

if __name__ == "__main__":
    main()
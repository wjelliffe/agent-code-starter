#!/usr/bin/env python3
import json
import re
import sys

STRICT_PATTERNS = [
    ("authentication/authorization", r"\b(oauth|authentication|authorization|authn|authz|rbac|access control|permission(s)?|login|session cookie)\b"),
    ("security/secrets", r"\b(security|secret(s)?|token(s)?|credential(s)?|encryption|cryptograph|csrf|xss|sql injection)\b"),
    ("data migration/integrity", r"\b(schema migration|migration(s)?|backfill|data integrity|data loss|database schema)\b"),
    ("transactions/concurrency", r"\b(transaction(s)?|concurren|race condition|idempotenc|locking|atomicity)\b"),
    ("payments/billing", r"\b(payment(s)?|billing|charge(s)?|refund(s)?|stripe)\b"),
    ("production infrastructure", r"\b(terraform|kubernetes|production infrastructure|infra change|deployment pipeline|database failover)\b"),
    ("explicit rigorous process", r"\b(full sdlc|strict validation|strict tdd|test[- ]driven|tdd)\b"),
    ("coupled systems", r"\b(multiple subsystems|cross[- ]system|cross[- ]service|distributed transaction)\b"),
]

def classify(text):
    lowered = text.lower()
    reasons = [label for label, pattern in STRICT_PATTERNS if re.search(pattern, lowered)]
    return {"mode": "sdlc-do" if reasons else "implement", "reasons": reasons, "advisory": True}

def main():
    text = " ".join(sys.argv[1:]).strip() if len(sys.argv) > 1 else sys.stdin.read().strip()
    print(json.dumps(classify(text), indent=2))

if __name__ == "__main__":
    main()

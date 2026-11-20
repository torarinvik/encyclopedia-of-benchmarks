# Package inventory

This package contains the bounded odd/even successor reachability contract,
two structurally independent references, 15 scalar workload cases, provenance
and rights notes, and ten native language ports. `check_inventory.py` performs
static file and metadata checks only; it does not build or execute ports.

The bounded input is at most 65 valid and 66 parseable i64 words. Outputs are
the good-start count `1..64` or malformed-frame sentinel `-1`. The workload
declares a 4,096-byte conservative workspace cap.

Duplicate disposition: next-greater/next-smaller packages expose successor
elements, and Jump Game packages use explicit distance bounds. Neither profile
implements value-ordered alternating transitions and reachability states.

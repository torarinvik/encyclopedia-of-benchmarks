# Static package inventory

This package provides `brzozowski_dfa_minimization` through the
`i64_array_scalar` ABI in ten language files listed in `INVENTORY.json`.
The complete binary DFA is bounded to three states; reverse/subset
construction has stage bounds of 8 and 256 states and an 8,192-byte declared
workspace cap.

Package metadata includes both method references, eleven pinned fixtures,
provenance/rights, and the static checker. The primary uses reversal and subset
construction twice; the independent reference uses reachability and iterative
pair distinguishability. The checker records source paths, fixture IDs, and
the fixed contract bounds. The largest fixed-array payload is 2,616 bytes;
Mojo uses 558 machine integers (4,464 payload bytes) across fixed-length lists.
The checker has not been run, and no source was compiled or executed.

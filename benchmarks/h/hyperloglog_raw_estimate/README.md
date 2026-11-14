# HyperLogLog raw estimate

This in-progress benchmark maintains the original HyperLogLog register sketch
for a supplied stream of 32-bit hash values and returns its uncorrected raw
estimate as an exact rational. It differs from the existing `hyper_log_log`
package, which preserves a source-specific identity-indexed calculation over
only touched registers rather than the paper's fixed buckets and full sum.

## Contract

The `i64_array_bytes_output` input is `[n,hash0,...,hash(n-1)]`, where
`0 <= n <= 128`, each hash is an integer in `[0,2^32-1]`, and the length is
exactly `n+1`. Duplicate hashes are allowed. The first four bits choose one
of 16 registers; the remaining 28 bits determine rank as one plus the number
of leading zeros, with the all-zero suffix assigned rank 29. The register
stores the maximum observed rank. All 16 registers, including untouched
zeros, contribute to the raw estimate.

Output is 18 signed i64 little-endian words `[numerator,denominator,R0,...,R15]`.
The first two words give the reduced exact fraction for
`(673/1000)*16^2 / sum(2^-Rj)`, using the paper's `m=16` calibration constant
as the stated exact decimal approximation. Invalid input returns `-1`; a null
or less-than-144-byte output returns `-2` without writes. Empty input means
the valid frame `[0]` and has the uncorrected raw estimate, not zero.
Maximum valid and parseable lengths are 129 and 130 i64 words.

This is the register-update and raw-estimate core. It intentionally does not
claim to implement the original small- and large-range correction branches,
hash generation, or HyperLogLog++ bias correction. Supplied hashes make the
bit-level algorithm deterministic. With 16 fixed registers, update and
aggregation cost O(n+16) time and O(16) space.

Source: Flajolet, Fusy, Gandouet and Meunier, “HyperLogLog: the analysis of a
near-optimal cardinality estimation algorithm,” *DMTCS Proceedings* (2007),
[publisher's article record](https://dmtcs.episciences.org/en/articles/3545).
The method is independently implemented from its mathematical description;
no source code, prose, or examples are copied. A bounded workload, independent
exact-rational reference, and ten language drafts are present. A separate
[corrected-estimate draft](../hyperloglog_corrected_estimate/README.md) covers
the original correction branches. The byte-output runner and verifier
are wired to this raw core; verifier source covers all buckets and possible
ranks, duplicates, malformed frames, and the maximum input. Nothing has been
executed.

| Language | Draft port |
| --- | --- |
| C | [C](../../../c/h/hyperloglog_raw_estimate.c) |
| C3 | [C3](../../../c3/h/hyperloglog_raw_estimate.c3) |
| C++ | [C++](../../../cpp/h/hyperloglog_raw_estimate.cpp) |
| Elisa | [Elisa](../../../elisa/h/hyperloglog_raw_estimate.elisa) |
| Mojo | [Mojo](../../../mojo/h/hyperloglog_raw_estimate.mojo) |
| Nim | [Nim](../../../nim/h/hyperloglog_raw_estimate.nim) |
| Odin | [Odin](../../../odin/h/hyperloglog_raw_estimate.odin) |
| Rust | [Rust](../../../rust/h/hyperloglog_raw_estimate.rs) |
| V | [V](../../../v/h/hyperloglog_raw_estimate.v) |
| Zig | [Zig](../../../zig/h/hyperloglog_raw_estimate.zig) |

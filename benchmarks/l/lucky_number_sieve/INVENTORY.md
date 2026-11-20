# Implementation inventory

All ten source ports are present. This inventory is a static source record;
the files have not been built or executed. The shared byte-output
runner/verifier, suite bounds, and package static-check dispatch are registered;
neither the package checker nor the dedicated verifier has been run.

| Language | Source | Status |
|---|---|---|
| C | [`c/l/lucky_number_sieve.c`](../../../c/l/lucky_number_sieve.c) | present, unbuilt |
| C3 | [`c3/l/lucky_number_sieve.c3`](../../../c3/l/lucky_number_sieve.c3) | present, unbuilt |
| C++ | [`cpp/l/lucky_number_sieve.cpp`](../../../cpp/l/lucky_number_sieve.cpp) | present, unbuilt |
| Elisa | [`elisa/l/lucky_number_sieve.elisa`](../../../elisa/l/lucky_number_sieve.elisa) | present, unbuilt |
| Mojo | [`mojo/l/lucky_number_sieve.mojo`](../../../mojo/l/lucky_number_sieve.mojo) | present, unbuilt |
| Nim | [`nim/l/lucky_number_sieve.nim`](../../../nim/l/lucky_number_sieve.nim) | present, unbuilt |
| Odin | [`odin/l/lucky_number_sieve.odin`](../../../odin/l/lucky_number_sieve.odin) | present, unbuilt |
| Rust | [`rust/l/lucky_number_sieve.rs`](../../../rust/l/lucky_number_sieve.rs) | present, unbuilt |
| V | [`v/l/lucky_number_sieve.v`](../../../v/l/lucky_number_sieve.v) | present, unbuilt |
| Zig | [`zig/l/lucky_number_sieve.zig`](../../../zig/l/lucky_number_sieve.zig) | present, unbuilt |

The dedicated verifier is [`benchmarks/verify_lucky_number_sieve.py`](../../verify_lucky_number_sieve.py); it has not been run.

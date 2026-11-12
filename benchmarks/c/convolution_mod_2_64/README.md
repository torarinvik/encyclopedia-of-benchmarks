# Convolution modulo 2^64

This benchmark follows the [Library Checker Convolution (Mod 2^64) task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/convolution_mod_2_64/task.md), its [official limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/convolution_mod_2_64/info.toml), and the published five-prime NTT/CRT method as an algorithm reference. The ports and direct oracle are clean-room implementations.

## Contract

Input is `[N, M, a_0, ..., a_(N-1), b_0, ..., b_(M-1)]`. The official task allows both lengths through 524,288. The local profile bounds each length to 64, so the padded NTT length is at most 128 and a direct oracle remains practical. Each coefficient is an arbitrary unsigned 64-bit value. Since the shared ABI transports signed i64 values, each input value is interpreted by its raw two's-complement bit pattern; negative signed values represent unsigned coefficients with the high bit set. Output is the full linear product in increasing degree order, with each residue modulo `2^64` encoded as eight little-endian bytes.

Invalid input returns `-1`. A null output or output capacity below `8*(N+M-1)` returns `-2` without writing. Maximum valid/parseable input lengths are 130/131 signed i64 values; maximum output is 1,016 bytes. The workspace field is 8,192 bytes, which also covers the two 128-entry transform buffers and five 127-entry residue arrays used internally.

## Algorithm

For each of five NTT-friendly primes, the ports reduce each unsigned input word to that prime, perform a radix-2 NTT convolution, and retain every output residue. Mixed-radix Garner reconstruction combines the five residues; unsigned 64-bit arithmetic keeps only the low 64 bits, exactly implementing reduction modulo `2^64`. The product of the five primes exceeds `2^149`, while with lengths at most 64 each exact coefficient is below `64*(2^64-1)^2 < 2^134`, so the residue tuple uniquely identifies the integer coefficient before wraparound. Runtime is `O(5 L log L)` for padded transform length `L`; workspace is `O(L+N+M)` in fixed transform and residue buffers, with `L<=128` and at most 127 outputs.

The independent [Python oracle](../../convolution_mod_2_64_oracle.py) directly accumulates all coefficient pairs in `O(N*M)` time using arbitrary-precision integers and masks each sum to 64 bits. The fixed-prime [`convolution_mod`](../convolution_mod/README.md) uses one NTT over its output field; [`convolution_mod_1000000007`](../convolution_mod_1000000007/README.md) uses three NTT primes and reconstructs modulo a prime target. This profile accepts every 64-bit coefficient pattern and uses five-prime exact reconstruction followed by word wraparound, which exercises a distinct coefficient ring and CRT width.

[`workload.json`](workload.json) covers unsigned high-bit patterns, wraparound, unequal lengths, and output errors. The verifier adds deterministic maximum-length, dense, sparse, malformed-frame, null, and capacity cases.

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/convolution_mod_2_64.c`](../../../c/c/convolution_mod_2_64.c) |
| C3 | [`c3/c/convolution_mod_2_64.c3`](../../../c3/c/convolution_mod_2_64.c3) |
| C++ | [`cpp/c/convolution_mod_2_64.cpp`](../../../cpp/c/convolution_mod_2_64.cpp) |
| Elisa | [`elisa/c/convolution_mod_2_64.elisa`](../../../elisa/c/convolution_mod_2_64.elisa) |
| Mojo | [`mojo/c/convolution_mod_2_64.mojo`](../../../mojo/c/convolution_mod_2_64.mojo) |
| Nim | [`nim/c/convolution_mod_2_64.nim`](../../../nim/c/convolution_mod_2_64.nim) |
| Odin | [`odin/c/convolution_mod_2_64.odin`](../../../odin/c/convolution_mod_2_64.odin) |
| Rust | [`rust/c/convolution_mod_2_64.rs`](../../../rust/c/convolution_mod_2_64.rs) |
| V | [`v/c/convolution_mod_2_64.v`](../../../v/c/convolution_mod_2_64.v) |
| Zig | [`zig/c/convolution_mod_2_64.zig`](../../../zig/c/convolution_mod_2_64.zig) |

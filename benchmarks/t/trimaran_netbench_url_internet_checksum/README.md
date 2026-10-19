# Trimaran NetBench URL internet checksum helper

This package ports the standalone `internet_checksum` helper in the pinned
`Trimaran/netbench-url/url.c` source. The upstream launcher is
[`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/netbench-url/info.sh)
and runs a larger URL routing workload over packet fixtures. This bounded
package covers only the helper; it does not implement routing rules, packet
generation, Boyer–Moore searches, or the launcher report.

The input is `[mode, byte_count, byte_0, ...]`, with at most 64 bytes.
`mode=0` reproduces the source without its `LITTLE_ENDIAN` output-swap branch;
`mode=1` reproduces that branch. Both modes interpret the source's native
16-bit loads as little-endian, matching the bounded profile's declared host
model. The source accumulates each promoted `~unsigned short` into a 64-bit
`unsigned long`, handles an odd final byte without complementing it, folds
carry until 16 bits remain, then optionally swaps the result bytes. These
details preserve the pinned helper instead of silently normalizing it to a
different checksum convention.

Malformed frames, invalid modes, lengths, or byte values return `-1`.
Valid results are in `0..65535`. The ABI is `i64_array_scalar`, and the
exported symbol is `trimaran_netbench_url_internet_checksum`.

Source: [`url.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/netbench-url/url.c),
commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, function
`internet_checksum`. The complete source permission and warranty notice is
bundled in [`LICENSE_NOTICE.txt`](LICENSE_NOTICE.txt). The independent
Python oracle is [`trimaran_netbench_url_internet_checksum_oracle.py`](../../trimaran_netbench_url_internet_checksum_oracle.py).

| Language | Port |
|---|---|
| C | [`c/t/trimaran_netbench_url_internet_checksum.c`](../../../c/t/trimaran_netbench_url_internet_checksum.c) |
| C3 | [`c3/t/trimaran_netbench_url_internet_checksum.c3`](../../../c3/t/trimaran_netbench_url_internet_checksum.c3) |
| C++ | [`cpp/t/trimaran_netbench_url_internet_checksum.cpp`](../../../cpp/t/trimaran_netbench_url_internet_checksum.cpp) |
| Elisa | [`elisa/t/trimaran_netbench_url_internet_checksum.elisa`](../../../elisa/t/trimaran_netbench_url_internet_checksum.elisa) |
| Nim | [`nim/t/trimaran_netbench_url_internet_checksum.nim`](../../../nim/t/trimaran_netbench_url_internet_checksum.nim) |
| Odin | [`odin/t/trimaran_netbench_url_internet_checksum.odin`](../../../odin/t/trimaran_netbench_url_internet_checksum.odin) |
| Rust | [`rust/t/trimaran_netbench_url_internet_checksum.rs`](../../../rust/t/trimaran_netbench_url_internet_checksum.rs) |
| V | [`v/t/trimaran_netbench_url_internet_checksum.v`](../../../v/t/trimaran_netbench_url_internet_checksum.v) |
| Zig | [`zig/t/trimaran_netbench_url_internet_checksum.zig`](../../../zig/t/trimaran_netbench_url_internet_checksum.zig) |

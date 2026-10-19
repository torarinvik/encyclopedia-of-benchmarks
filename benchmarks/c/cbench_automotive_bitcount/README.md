# cBench automotive bitcount

This package ports the automotive bitcount benchmark from the pinned
[`cBench/automotive_bitcount`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/automotive_bitcount/src)
source in `lac-dcc/Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`.

`bitcnts.c` runs seven selected bit counting kernels in source order. Each
kernel starts its own stream at `1` and increments the value by `13` for every
iteration. The cBench dataset 1 command supplies `1125000`; its loop wrapper
repeats the driver 80 times and prints only the last pass. Each pass is
deterministic, so the scalar suite models one driver pass and returns the
ordered weighted checksum of the seven printed totals. The `info.sh` file
leaves `RUN_OPTIONS` blank; the iteration argument comes from the cBench
dataset description. The bounded suite profile uses dataset 1's 1,125,000
iterations as its upper limit.

Because every kernel receives the same positive stream, all seven totals match.
At 1,125,000 iterations each total is `13244094`; the weighted result is
`370834632`. Zero iterations returns `0`. Inputs outside 0 through 1,125,000
return `-1`. Throughout this profile the generated values stay below `2^24`,
so all seven source kernels count the same 24 or fewer low bits.

This package remains distinct from MiBench `automotive_bitcount`: MiBench
starts its seven kernels from separate PRNG values, while this cBench driver
resets each kernel's stream to `1`. The one-value `count_set_bits` algorithm
does not represent either benchmark's seven accumulated totals.

The independent oracle in
[`benchmarks/cbench_automotive_bitcount_oracle.py`](../../cbench_automotive_bitcount_oracle.py)
uses a floor-sum count over the arithmetic progression rather than the source
kernels.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/cbench_automotive_bitcount.c](../../../c/c/cbench_automotive_bitcount.c) |
| C3 | [c3/cbench_automotive_bitcount.c3](../../../c3/c/cbench_automotive_bitcount.c3) |
| C++ | [cpp/cbench_automotive_bitcount.cpp](../../../cpp/c/cbench_automotive_bitcount.cpp) |
| Elisa | [elisa/cbench_automotive_bitcount.elisa](../../../elisa/c/cbench_automotive_bitcount.elisa) |
| Nim | [nim/cbench_automotive_bitcount.nim](../../../nim/c/cbench_automotive_bitcount.nim) |
| Odin | [odin/cbench_automotive_bitcount.odin](../../../odin/c/cbench_automotive_bitcount.odin) |
| Rust | [rust/cbench_automotive_bitcount.rs](../../../rust/c/cbench_automotive_bitcount.rs) |
| V | [v/cbench_automotive_bitcount.v](../../../v/c/cbench_automotive_bitcount.v) |
| Zig | [zig/cbench_automotive_bitcount.zig](../../../zig/c/cbench_automotive_bitcount.zig) |

Run the shared scalar suite with:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm cbench_automotive_bitcount --language c
python3 benchmarks/run_scalar.py --build-manifest build/scalar/c/cbench_automotive_bitcount/c/build.json
python3 benchmarks/verify_scalar.py --algorithms cbench_automotive_bitcount --languages c
```

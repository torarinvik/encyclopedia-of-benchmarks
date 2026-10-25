# MiBench automotive-bitcount

This package ports the `automotive-bitcount` benchmark from the pinned
[`MiBench/automotive-bitcount` source](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/automotive-bitcount)
in `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`.
The launcher compiles nine C files with `-lm` and runs `bitcnts 1125000`.
The source distribution's accompanying `LICENSE` describes the code as free
with no restrictions.

`bitcnts.c` benchmarks seven selected implementations: Kernighan bit clearing,
parallel bit summation, recursive and fixed-width nybble tables, two four-byte
table methods, and shift/test. The pinned driver initializes its local random
generator with seed one, draws one start value for each algorithm in source
order, then advances that algorithm's input by 13 on each iteration. The
bounded scalar input is an iteration count from 0 through 1,125,000, matching
the launcher profile. These generated values stay positive and below 2^31.

The original executable prints seven separate `Bits:` totals. The scalar ABI
returns their ordered weighted checksum, `sum((position + 1) * total)` for
one-based source positions. At the launcher's 1,125,000 iterations, the seven
totals are `13254056`, `13255501`, `13257159`, `13246703`, `13250340`,
`13249450`, and `13257011`, yielding `371070824`. Zero iterations returns
zero; input outside the bounded range returns `-1`. The existing `count_set_bits`
entry handles one integer, while this benchmark runs the seven kernels over
separate deterministic streams and combines their accumulated totals.

The independent oracle in
[`benchmarks/automotive_bitcount_oracle.py`](../../automotive_bitcount_oracle.py)
computes each algorithm total and the same weighted checksum.

The cBench `automotive_bitcount` copy uses the same seven counting algorithms
with a different deterministic input stream and outer repeat count. It is
cross-referenced here as a workload variant rather than kept as a duplicate
algorithm package.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/a/automotive_bitcount.c](../../../c/a/automotive_bitcount.c) |
| C3 | [c3/a/automotive_bitcount.c3](../../../c3/a/automotive_bitcount.c3) |
| C++ | [cpp/a/automotive_bitcount.cpp](../../../cpp/a/automotive_bitcount.cpp) |
| Elisa | [elisa/a/automotive_bitcount.elisa](../../../elisa/a/automotive_bitcount.elisa) |
| Nim | [nim/a/automotive_bitcount.nim](../../../nim/a/automotive_bitcount.nim) |
| Odin | [odin/a/automotive_bitcount.odin](../../../odin/a/automotive_bitcount.odin) |
| Rust | [rust/a/automotive_bitcount.rs](../../../rust/a/automotive_bitcount.rs) |
| V | [v/a/automotive_bitcount.v](../../../v/a/automotive_bitcount.v) |
| Zig | [zig/a/automotive_bitcount.zig](../../../zig/a/automotive_bitcount.zig) |

Run the shared scalar suite with:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm automotive_bitcount --language c
python3 benchmarks/run_scalar.py --build-manifest build/scalar/a/automotive_bitcount/c/build.json
python3 benchmarks/verify_scalar.py --algorithms automotive_bitcount --languages c
```

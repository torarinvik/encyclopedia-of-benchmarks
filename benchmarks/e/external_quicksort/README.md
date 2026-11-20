# External Quicksort

This is a bounded, in-place profile of NIST DADS external quicksort. It uses a
fixed sorted buffer of eight values in place of a single pivot. Each partition
fills that buffer by reading from the two ends of the input range, balancing
the number of reads taken from each end. With this even buffer size, the first
eight reads take four values from each end.

After the buffer is full, a value above its maximum is written toward the upper
end; a value below its minimum is written toward the lower end. A value within
the buffer's range replaces an extreme buffer value, which is written toward
the side with more available space. The buffer is kept sorted. The algorithm
tracks the outermost writes that break the established lower or upper ordering,
flushes the buffer between the resulting partitions, recursively sorts the
smaller partition, and iterates on the larger one.

## Contract

The benchmark uses the existing in-place `sort_call` ABI:

```c
void external_quicksort(int64_t *values, size_t length);
```

It sorts 0–1,024 signed 64-bit values in ascending order. The pivot buffer is
fixed at eight values. Inputs above the bound are left unchanged. The
implementation is unstable. Its workspace budget is 768 bytes for at most
twelve active frames of eight signed 64-bit buffer slots each; scalar bounds
and call metadata are excluded. All workspace belongs to the timed call.
Endpoint accesses are simulated against the in-memory array; the profile does
not perform disk I/O.

The primary oracle follows the fixed-buffer endpoint partition procedure. The
independent oracle uses the host language's built-in integer ordering. The
dedicated verifier compares both references over exhaustive tiny inputs and a
bounded collection of larger edge cases, then uses the shared sort checker and
runner. It has not been run.

## Distinction and sources

The method differs from ordinary local quicksort ports, which select a pivot
and perform a conventional two-way partition. Its defining operation is a
sorted multi-value buffer fed from both range endpoints, with inward writes,
order-violation bounds, and smaller-side recursion. It also differs from
external merge sort, which constructs and merges runs across passes.

The method description is from the [NIST Dictionary of Algorithms and Data
Structures entry for external quicksort](https://xlinux.nist.gov/dads/HTML/externalQuicksort.html).
The linked mechanics reference is Gonnet and Baeza-Yates, *Handbook of
Algorithms and Data Structures*, `446.sort.c`, [linked implementation
description](https://users.dcc.uchile.cl/~rbaeza/handbook/algs/4/446.sort.c.html).
These sources were consulted for algorithm mechanics only. The benchmark
implementations are clean-room ports and do not reproduce the reference code.

See [`workload.json`](workload.json), [`RIGHTS.md`](RIGHTS.md), and
[`INVENTORY.md`](INVENTORY.md). The package static checker is
[`verify_workload.py`](verify_workload.py); the custom `sort_call` verifier is
[`benchmarks/verify_external_quicksort.py`](../../verify_external_quicksort.py).

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/e/external_quicksort.c`](../../../c/e/external_quicksort.c) |
| C3 | [`c3/e/external_quicksort.c3`](../../../c3/e/external_quicksort.c3) |
| C++ | [`cpp/e/external_quicksort.cpp`](../../../cpp/e/external_quicksort.cpp) |
| Elisa | [`elisa/e/external_quicksort.elisa`](../../../elisa/e/external_quicksort.elisa) |
| Mojo | [`mojo/e/external_quicksort.mojo`](../../../mojo/e/external_quicksort.mojo) |
| Nim | [`nim/e/external_quicksort.nim`](../../../nim/e/external_quicksort.nim) |
| Odin | [`odin/e/external_quicksort.odin`](../../../odin/e/external_quicksort.odin) |
| Rust | [`rust/e/external_quicksort.rs`](../../../rust/e/external_quicksort.rs) |
| V | [`v/e/external_quicksort.v`](../../../v/e/external_quicksort.v) |
| Zig | [`zig/e/external_quicksort.zig`](../../../zig/e/external_quicksort.zig) |

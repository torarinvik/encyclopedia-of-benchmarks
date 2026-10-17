# Shuf

Select a bounded random sample from a finite iterator and return the selected
values in the source's slot order. This package isolates `shuf` from the pinned
[TheAlgorithms/JavaScript `Shuf.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/Shuf.js)
at commit `5c39e87a9a31f279c60f830ad74a845e4788a517`.

## Contract

Input is a signed 64-bit array `[n, k, values..., draws...]`. `n` is the number
of source values (0–32), `k` is the requested sample size (1–32), each value is
a signed i32, and there must be exactly `n` forced draws. The maximum valid
input length is 66; malformed cases may contain at most 67 values. A draw is
the exact integer index the source obtains from
`floor(Math.random() * bound)`, so the caller must supply a value in
`0..bound-1`. No random-number generator is part of the benchmark.

The source first places the first `min(n, k)` values into slots in a `k`-item
array. Each placement starts at its forced draw and advances cyclically until
it finds an empty slot. If `n < k`, empty slots are removed and remaining
values stay in slot order. For each later value, the source increments the
number seen, draws an index in that range, and replaces the corresponding
sample slot only when the draw is less than `k`. The result contains
`min(n, k)` values. This preserves both the source's initial placement and
reservoir-replacement stages; it is not a Fisher–Yates shuffle.

Output is the result values encoded as four-byte little-endian two's-complement
i32 values. Success returns the number of values written. Malformed input
returns `-1`; insufficient output capacity or a null output pointer returns
`-2`. Input validation happens before output-capacity checks. A valid empty
sample succeeds with return value zero when the output pointer is non-null,
even when its capacity is zero. Null input is invalid.

See [`workload.json`](workload.json) for placement collisions, reservoir
replacement and rejection, short streams, duplicates, signed boundaries,
malformed inputs, and output-capacity cases. The independent oracle is
[`benchmarks/shuf_oracle.py`](../../shuf_oracle.py).

## Source

- [JavaScript `Shuf.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/Shuf.js)

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/s/shuf.c`](../../../c/s/shuf.c) |
| C3 | [`c3/s/shuf.c3`](../../../c3/s/shuf.c3) |
| C++ | [`cpp/s/shuf.cpp`](../../../cpp/s/shuf.cpp) |
| Elisa | [`elisa/s/shuf.elisa`](../../../elisa/s/shuf.elisa) |
| Nim | [`nim/s/shuf.nim`](../../../nim/s/shuf.nim) |
| Odin | [`odin/s/shuf.odin`](../../../odin/s/shuf.odin) |
| Rust | [`rust/s/shuf.rs`](../../../rust/s/shuf.rs) |
| V | [`v/s/shuf.v`](../../../v/s/shuf.v) |
| Zig | [`zig/s/shuf.zig`](../../../zig/s/shuf.zig) |

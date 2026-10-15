# Figurate number predicates

## Contract

For a nonnegative input `n` from 0 through 1,000,000, report whether it is triangular, tetrahedral, and pentatope. The signed scalar result packs the three booleans into bits: bit 0 is triangular, bit 1 is tetrahedral, and bit 2 is pentatope. Return `-1` for negative inputs or values above the benchmark bound.

The benchmark keeps the pinned JavaScript predicates' integer behavior while bounding the input so all terms and intermediate products are exact in signed 64-bit arithmetic. The triangular search starts at index 0; the tetrahedral and pentatope searches start at index 1. Each search stops when its next term exceeds `n`.

## Source semantics

The pinned [TheAlgorithms JavaScript `FigurateNumber.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/FigurateNumber.js) exports `isTriangular`, `isTetrahedral`, `isPentatope`, and `checkAll`. `checkAll` returns the three booleans; this benchmark packs them into the scalar bitfield above. The existing triangular and tetrahedral sequence benchmarks return terms by index, while this package checks membership of a supplied number.

## Workload

[`workload.json`](workload.json) includes initial terms, values belonging to more than one family, ordinary nonmembers, the maximum supported input, and invalid boundaries.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/figurate_number.c`](../../../c/f/figurate_number.c) |
| C3 | [`c3/f/figurate_number.c3`](../../../c3/f/figurate_number.c3) |
| C++ | [`cpp/f/figurate_number.cpp`](../../../cpp/f/figurate_number.cpp) |
| Elisa | [`elisa/f/figurate_number.elisa`](../../../elisa/f/figurate_number.elisa) |
| Nim | [`nim/f/figurate_number.nim`](../../../nim/f/figurate_number.nim) |
| Odin | [`odin/f/figurate_number.odin`](../../../odin/f/figurate_number.odin) |
| Rust | [`rust/f/figurate_number.rs`](../../../rust/f/figurate_number.rs) |
| V | [`v/f/figurate_number.v`](../../../v/f/figurate_number.v) |
| Zig | [`zig/f/figurate_number.zig`](../../../zig/f/figurate_number.zig) |

Build with `python3 benchmarks/build_scalar.py --algorithm figurate_number --language LANGUAGE`; the workload uses the standard scalar runner.

# Zeller's Congruence

Return the weekday for a Gregorian calendar date using the arithmetic in the pinned Java candidate.

## Contract

- Pack the input as `[year, month, day]` in the shared `i64_array_scalar` ABI.
- Years are in `46..=8499`, matching the Java source's accepted range. Month and day must form a valid date in the proleptic Gregorian calendar. Invalid input returns `-1`.
- A valid result is a weekday number: Sunday `0`, Monday `1`, Tuesday `2`, Wednesday `3`, Thursday `4`, Friday `5`, Saturday `6`.
- January and February are treated as months 13 and 14 of the preceding year. The month term is computed as integer `(260 * month - 539) / 100`, which gives the same truncated value as the Java source's `(int)(2.6 * month - 5.39)` for those adjusted month values.

## Source behavior and scope

The Java method accepts a ten-character `MM-DD-YYYY` or `MM/DD/YYYY` date string, parses numeric month/day/year fields, restricts years to 46 through 8499, and validates the complete date with `LocalDate`. It returns a sentence containing the weekday name. The benchmark uses numeric fields and returns the weekday index so the calculation can use one portable scalar ABI.

The Java implementation uses Gregorian arithmetic. Although its documentation says the method handles Julian dates too, it does not select a Julian formula. The Python candidate also uses Python's Gregorian `date` for validation; the TypeScript candidate has an optional Julian mode, which this benchmark excludes. The shared contract uses a proleptic Gregorian calendar throughout.

## Workload

[`workload.json`](workload.json) includes the Java and TypeScript date examples, leap days and century boundaries, the year limits, invalid dates, and malformed array lengths. Expected weekday indices use Sunday as zero.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/z/zellers_congruence.c`](../../../c/z/zellers_congruence.c) |
| C3 | [`c3/z/zellers_congruence.c3`](../../../c3/z/zellers_congruence.c3) |
| C++ | [`cpp/z/zellers_congruence.cpp`](../../../cpp/z/zellers_congruence.cpp) |
| Elisa | [`elisa/z/zellers_congruence.elisa`](../../../elisa/z/zellers_congruence.elisa) |
| Nim | [`nim/z/zellers_congruence.nim`](../../../nim/z/zellers_congruence.nim) |
| Odin | [`odin/z/zellers_congruence.odin`](../../../odin/z/zellers_congruence.odin) |
| Rust | [`rust/z/zellers_congruence.rs`](../../../rust/z/zellers_congruence.rs) |
| V | [`v/z/zellers_congruence.v`](../../../v/z/zellers_congruence.v) |
| Zig | [`zig/z/zellers_congruence.zig`](../../../zig/z/zellers_congruence.zig) |

## Upstream references

- [TheAlgorithms/Java `ZellersCongruence.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/ZellersCongruence.java)
- [TheAlgorithms/Python `zellers_congruence.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/zellers_congruence.py)
- [TheAlgorithms/TypeScript `zellers_congruence.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/zellers_congruence.ts)

Build with the `i64_array_scalar` ABI family and record with `benchmarks/run_i64_array_scalar.py`.

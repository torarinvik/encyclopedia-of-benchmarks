# Upper bound

## Contract

This benchmark ports TheAlgorithms/Java's UpperBound.find implementation from [the pinned UpperBound.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/UpperBound.java). The pinned [PHP UpperBound.php](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Searches/UpperBound.php) sibling uses a conventional half-open boundary search and returns n when the target is at or above every value; Java's result is distinct at that endpoint.

The Java source recursively searches inclusive bounds [left, right], initially [0, n - 1]. If right <= left, it returns left without inspecting that final element. Otherwise it computes the midpoint, recurses left only when target < values[middle], and recurses right for equal or larger values. On a nonempty sorted array, this returns the first index whose value is greater than the target when that index exists, except that an insertion point at n is returned as n - 1. Empty input returns 0. Duplicate matches advance past the equal run when a later value exists.

The shared scalar ABI packs the target first, followed by 0 to 512 sorted nondecreasing signed int32 values:

    int64_t upper_bound(const int64_t *packed, size_t length);

The target and every array value must fit signed int32. A packed length of one represents an empty array and returns 0. Length zero, lengths above 513, out-of-domain values, and descending adjacent array values return -1. The parser accepts one over-limit packed record of length 514 so the function can return -1. A positive-length null pointer also returns -1. The independent oracle is [upper_bound_oracle.py](../../upper_bound_oracle.py); it uses a linear scan and preserves the Java source's final-index clamp.

## Workload

[workload.json](workload.json) includes empty and singleton arrays, values below and above the target, duplicate runs, int32 boundaries, the 512-value maximum array, malformed packed inputs, and a 513-value array over the valid bound. The timing model is the shared i64_array_scalar_call ABI.

## Implementations

The nine local ports preserve the Java inclusive recursion and its final-index clamp.

## Reviewed source

[TheAlgorithms/Java UpperBound.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/UpperBound.java)

[TheAlgorithms/PHP UpperBound.php](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Searches/UpperBound.php)

Both pinned source revisions are licensed under MIT: [Java LICENSE](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/LICENSE) and [PHP LICENSE](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/LICENSE).

## Build and record

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm upper_bound --language rust
    python3 benchmarks/run_i64_array_scalar.py --algorithm upper_bound
    python3 benchmarks/verify_i64_array_scalar.py --algorithm upper_bound

## Implementations

| Language | Source |
| --- | --- |
| C | [c/u/upper_bound.c](../../../c/u/upper_bound.c) |
| C3 | [c3/u/upper_bound.c3](../../../c3/u/upper_bound.c3) |
| C++ | [cpp/u/upper_bound.cpp](../../../cpp/u/upper_bound.cpp) |
| Elisa | [elisa/u/upper_bound.elisa](../../../elisa/u/upper_bound.elisa) |
| Nim | [nim/u/upper_bound.nim](../../../nim/u/upper_bound.nim) |
| Odin | [odin/u/upper_bound.odin](../../../odin/u/upper_bound.odin) |
| Rust | [rust/u/upper_bound.rs](../../../rust/u/upper_bound.rs) |
| V | [v/u/upper_bound.v](../../../v/u/upper_bound.v) |
| Zig | [zig/u/upper_bound.zig](../../../zig/u/upper_bound.zig) |

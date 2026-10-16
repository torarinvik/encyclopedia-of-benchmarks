# Euclidean Distance

This benchmark ports the n-dimensional distance functions found in the pinned [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/EuclideanDistance.js), [MATLAB-Octave](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/maths/euclidean_distance.m), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/euclidean_distance.py), [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/mathematics/euclidean_distance.r), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/euclidean_distance.rs) sources. The pinned JavaScript [`Coordinate.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/Coordinate.js) also supplies a two-dimensional Euclidean formula that is covered by this n-dimensional contract.

## Contract

- Input layout is [dimension, x0..x(n-1), y0..y(n-1)].
- Dimension is 0 through 128. Each coordinate is a signed integer from -1,000,000 through 1,000,000.
- Return sqrt(sum((xi - yi)^2)) as binary64.
- The array length must equal 1 + 2 * dimension. Malformed lengths or values return -1e300.
- Output tolerance is 1e-12 absolute and relative.
- Runtime is O(n); auxiliary space is O(1).

The sources differ on mismatched vector dimensions: MATLAB-Octave returns NaN, Python raises, JavaScript may ignore or read missing entries, and Rust zips to the shorter vector. The shared ABI requires an explicit dimension and exact array length, so those divergent cases map to the invalid sentinel.

## Workload and build

[workload.json](workload.json) covers zero-, one-, two-, three-, and four-dimensional vectors, identical vectors, malformed lengths, and invalid coordinates. Build with the i64_array_float64 family.

## Verification

Run the independent bounded oracle against the supported language ports with:

```sh
python3 benchmarks/verify_euclidean_distance.py
```

## Implementations

| Language | Source |
| --- | --- |
| C | [c/e/euclidean_distance.c](../../../c/e/euclidean_distance.c) |
| C3 | [c3/e/euclidean_distance.c3](../../../c3/e/euclidean_distance.c3) |
| C++ | [cpp/e/euclidean_distance.cpp](../../../cpp/e/euclidean_distance.cpp) |
| Elisa | [elisa/e/euclidean_distance.elisa](../../../elisa/e/euclidean_distance.elisa) |
| Nim | [nim/e/euclidean_distance.nim](../../../nim/e/euclidean_distance.nim) |
| Odin | [odin/e/euclidean_distance.odin](../../../odin/e/euclidean_distance.odin) |
| Rust | [rust/e/euclidean_distance.rs](../../../rust/e/euclidean_distance.rs) |
| V | [v/e/euclidean_distance.v](../../../v/e/euclidean_distance.v) |
| Zig | [zig/e/euclidean_distance.zig](../../../zig/e/euclidean_distance.zig) |

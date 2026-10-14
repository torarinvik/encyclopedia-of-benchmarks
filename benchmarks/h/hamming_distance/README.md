# Hamming distance

Hamming distance counts differing positions between equal-width values. The pinned C source implements the string form, while the C++ and Rust modules provide both string and integer forms. The benchmark selects the fixed-width integer form: C++ uses XOR plus bit counting, and Rust exposes the same unsigned 64-bit operation ([C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/misc/hamming_distance.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/bit_manipulation/hamming_distance.cpp), [Rust bit implementation](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/bit_manipulation/hamming_distance.rs)). The nine ports use the same unsigned 64-bit input domain and return the number of differing bit positions.

## Interface and contract

```c
int64_t hamming_distance(uint64_t left, uint64_t right);
```

Both inputs range from `0` through `2^64 - 1`. The result is the number of positions where the two 64-bit values differ, including leading zero positions, so it ranges from `0` to `64`. There are no invalid inputs or error results. The implementation compares the low bits and shifts both unsigned values until both are zero; it takes at most 64 iterations and constant auxiliary storage. It uses portable integer operations without architecture-specific population-count instructions.

The upstream C string function accepts two null-terminated strings and assumes the second has at least the first string's length. That string API has a different input contract, so the local benchmark selects the unsigned integer variant available in the reviewed C++ and Rust files and supplies the corresponding portable C implementation.

## Workload and correctness

[`workload.json`](workload.json) contains 106 fixed input pairs, including all 64 one-bit masks, all-zero and all-one values, alternating patterns, upstream examples, and deterministic random pairs. The verifier checks every pair in the workload plus all 65,536 pairs of 8-bit values, boundary patterns, and deterministic random 64-bit pairs against an independent bit-string oracle. Each language passes 66,136 oracle pairs.

Build any port with the shared binary-scalar recipe:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm hamming_distance --language c
```

Record the published workload using its build manifest:

```sh
python3 benchmarks/run_binary_scalar.py \
  --build-manifest build/binary_scalar/h/hamming_distance/c/build.json
```

Verify the C ABI and workload recorder in all nine languages with:

```sh
python3 benchmarks/verify_binary_scalar.py \
  --elisa-compiler /absolute/path/to/elisac
```

The verification report is written to `build/binary_scalar/verification.json`. Verification samples validate output and record format; they are not suitable for comparing performance.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/h/hamming_distance.c`](../../../c/h/hamming_distance.c) | Portable implementation of the unsigned integer contract |
| C3 | [`c3/h/hamming_distance.c3`](../../../c3/h/hamming_distance.c3) | Independent portable implementation |
| C++ | [`cpp/h/hamming_distance.cpp`](../../../cpp/h/hamming_distance.cpp) | Independent portable implementation |
| Elisa | [`elisa/h/hamming_distance.elisa`](../../../elisa/h/hamming_distance.elisa) | Independent portable implementation |
| Nim | [`nim/h/hamming_distance.nim`](../../../nim/h/hamming_distance.nim) | Independent portable implementation |
| Odin | [`odin/h/hamming_distance.odin`](../../../odin/h/hamming_distance.odin) | Independent portable implementation |
| Rust | [`rust/h/hamming_distance.rs`](../../../rust/h/hamming_distance.rs) | Independent portable implementation |
| V | [`v/h/hamming_distance.v`](../../../v/h/hamming_distance.v) | Independent portable implementation |
| Zig | [`zig/h/hamming_distance.zig`](../../../zig/h/hamming_distance.zig) | Independent portable implementation |

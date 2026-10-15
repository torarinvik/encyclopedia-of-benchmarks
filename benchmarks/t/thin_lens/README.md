# Thin lens

This package benchmarks the three public operations in pinned Java [`ThinLens.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/physics/ThinLens.java): image distance, magnification, and whether an image is real.

## Contract

The `i64_array_float64` input is `[operation, a, b]`:

- Operation `0` computes image distance from focal length `f=a` and object distance `u=b`, using the source expression `1.0 / ((1.0 / f) - (1.0 / u))` in that order.
- Operation `1` computes magnification from image distance `v=a` and object distance `u=b`, using `v / u`.
- Operation `2` returns `1.0` when image distance `v=a` is positive and `0.0` otherwise. The unused `b` slot must be zero.

Both values are bounded signed integers in `[-1000,1000]`, a discrete subset of the source's binary64 inputs. For operation 0, both values must be nonzero and unequal; equality would make the source return infinity, outside this runner's finite-result contract. For operation 1, `b` must be nonzero. Operation 2 accepts zero and negative image distances. Any invalid selector, packing, bound, or operation-specific input returns `-1e300`. Valid results use binary64 with relative and absolute tolerance `1e-12`.

This is distinct from the nearby Python `lens_formulae` candidate. Its image-distance operation uses `1 / ((1/u) + (1/f))` and it exposes focal-length and object-distance functions instead of magnification and real-image classification. The Java implementation uses the Cartesian sign convention and the reciprocal subtraction shown above.

## Workload and recording

[`workload.json`](workload.json) includes each operation, signed values, source zero guards, the finite singularity boundary, and malformed inputs. Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm thin_lens --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/t/thin_lens/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/thin_lens.c`](../../../c/t/thin_lens.c) |
| C3 | [`c3/t/thin_lens.c3`](../../../c3/t/thin_lens.c3) |
| C++ | [`cpp/t/thin_lens.cpp`](../../../cpp/t/thin_lens.cpp) |
| Elisa | [`elisa/t/thin_lens.elisa`](../../../elisa/t/thin_lens.elisa) |
| Nim | [`nim/t/thin_lens.nim`](../../../nim/t/thin_lens.nim) |
| Odin | [`odin/t/thin_lens.odin`](../../../odin/t/thin_lens.odin) |
| Rust | [`rust/t/thin_lens.rs`](../../../rust/t/thin_lens.rs) |
| V | [`v/t/thin_lens.v`](../../../v/t/thin_lens.v) |
| Zig | [`zig/t/thin_lens.zig`](../../../zig/t/thin_lens.zig) |


# Maximum absolute magnitude

This benchmark returns the first value with the greatest absolute magnitude in a nonempty integer sequence. Ties preserve the first value, including when equal-magnitude values have opposite signs.

## Contract

- Input is `[value_count, value_0, ..., value_n]` with 1 through 256 values.
- Values are bounded to `[-1,000,000,000,000, 1,000,000,000,000]`, so absolute-value comparisons are safe on every target.
- Return the original signed value with the greatest magnitude. Empty, malformed, or out-of-range inputs return `-1`.

The shared contract follows the magnitude-based selection in the pinned Dart, F-Sharp, and Scala sources, as well as the `abs_max` helper in Python's `maths/abs.py`. The Ruby file named `abs_max.rb` instead computes the ordinary numeric maximum; that different behavior is recorded here and is not mixed into this contract.

## Workload and verification

[`workload.json`](workload.json) covers singleton and mixed-sign arrays, zero, equal-magnitude ties, bounds, and malformed inputs. [`verify_abs_extrema.py`](../../verify_abs_extrema.py) checks both absolute minimum and maximum against a direct sequence oracle in all nine languages.

## Reviewed TheAlgorithms sources

- [Dart `abs_max.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/abs_max.dart), [F-Sharp `AbsMax.fs`](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Math/AbsMax.fs), and [Scala `AbsMax.scala`](https://github.com/TheAlgorithms/Scala/blob/de555349d5effb87962d3116eb08c9f374065112/src/main/scala/Mathematics/AbsMax.scala) select by absolute magnitude.
- Python also defines `abs_max` in [`maths/abs.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/abs.py).
- [Ruby `abs_max.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/abs_max.rb) computes the ordinary numeric maximum instead.

## Implementations

The nine portable implementations use the shared `i64_array_scalar` ABI. Each source is under the `a` folder for its language.

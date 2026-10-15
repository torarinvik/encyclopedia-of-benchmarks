# Count sorted vowel strings

Counts length-`n` strings over the ordered vowels `a, e, i, o, u` whose characters are nondecreasing. Repetition is allowed.

## Contract

- Uses the `scalar` ABI with one signed integer input and returns an integer count.
- Accepts `n` from 0 through 30,000. Zero represents the empty string and returns 1.
- Inputs outside that range return `-1`.
- Computes `(n + 4) * (n + 3) * (n + 2) * (n + 1) / 24` in that multiplication order, then divides exactly by 24.
- At the upper bound, the product before division is 810,270,031,501,500,024, within signed 64-bit range; the count is 33,761,251,312,562,501.

## Source semantics

The benchmark follows the pinned [Ruby math implementation](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/count_sorted_vowel_strings.rb), which uses the closed form above. The same repository also has a [memoized dynamic-programming implementation](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/dynamic_programming/count_sorted_vowel_strings.rb). Its base case returns 1 for `n < 1`; for the benchmark's shared `n >= 0` domain, its recurrence counts the same strings and returns the same values. This package measures the math file's closed-form operation order.

The formula counts multisets of size `n` from five ordered vowel choices, equivalently `C(n + 4, 4)`. The bounded domain keeps both its intermediate product and result within signed 64-bit range.

## Workload and build

[`workload.json`](workload.json) covers the empty string, the source examples, the upper bound, and invalid inputs. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm count_sorted_vowel_strings --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/c/count_sorted_vowel_strings/rust/build.json
```

The nine implementations are in `c/c/count_sorted_vowel_strings.c`, `c3/c/count_sorted_vowel_strings.c3`, `cpp/c/count_sorted_vowel_strings.cpp`, `elisa/c/count_sorted_vowel_strings.elisa`, `nim/c/count_sorted_vowel_strings.nim`, `odin/c/count_sorted_vowel_strings.odin`, `rust/c/count_sorted_vowel_strings.rs`, `v/c/count_sorted_vowel_strings.v`, and `zig/c/count_sorted_vowel_strings.zig`.

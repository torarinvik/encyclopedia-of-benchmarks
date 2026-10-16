# Arithmetic mean

Compute the arithmetic mean of a nonempty array of signed integers and return a binary64 result. This benchmark normalizes the `average`, `average_mean`, `mean`, and `calculate_mean` source candidates to `sum(values) / length` with a floating result. Their empty-input behavior differs, and some integer-specific overloads truncate; this contract makes the result type explicit and uses fractional cases to preserve the mean rather than an integer quotient.

## Contract

- The input contains 1 to 4096 signed 64-bit values, each in `[-1,000,000,000, 1,000,000,000]`.
- Sum values in order using a signed 64-bit accumulator, convert that exact sum to binary64, then divide by the array length. Every partial sum is bounded by `4,096,000,000,000`, below `2^53`, so it is exactly representable and cannot overflow the accumulator.
- Return the binary64 quotient. Invalid or empty input returns the finite sentinel `-1e300`, outside the valid result range.
- The algorithm takes `O(n)` time and `O(1)` auxiliary space.

## Relationship to other candidates

The Rust `average.rs` defines `mean` as a sum followed by division and returns `None` for an empty vector. The JavaScript, Julia, Python, and Mojo `average_mean` implementations use the same arithmetic mean. The broader `mean` and `calculate_mean` candidates also compute sum divided by count. Empty-input outcomes vary among these sources, so the benchmark defines one shared sentinel. Integer-specialized forms in Rust, Kotlin, Ruby, and Solidity can truncate nonintegral means; this benchmark fixes a binary64 result and covers fractional means explicitly. The Go `arithmeticmean` candidate instead computes a two-value midpoint with bitwise operations, so it remains distinct.

- [Rust `average.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/average.rs)
- [Java `Average.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Average.java)
- [JavaScript `AverageMean.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/AverageMean.js)
- [Python `average_mean.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/average_mean.py)
- [Julia `average_mean.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/average_mean.jl)
- [Mojo `average_mean.mojo`](https://github.com/TheAlgorithms/Mojo/blob/de31759cab02892cb7ccc7767d97fc000b10fcae/maths/average_mean.mojo)
- [Ruby `average_mean.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/average_mean.rb)
- [Solidity `AverageMean.sol`](https://github.com/TheAlgorithms/Solidity/blob/08cba51fb38e276062b0c9791d7e0ee494ffa903/src/Maths/AverageMean.sol)
- [Go pairwise `arithmeticmean.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/binary/arithmeticmean.go)

## Workload and recording

The workload includes fractional positive and negative means, cancellation, an all-zero mean, the Rust source example, and invalid inputs. All nine ports use the shared `i64_array_float64` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm average --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/a/average/rust/build.json
```

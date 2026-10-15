# Prime factors

The pinned JavaScript, Julia, Python, Rust, and Scala sources factor positive integers with trial division. Most emit prime factors with multiplicity. The Python file also exposes a separate distinct-factor helper; this benchmark uses the repeated form. The Julia implementation has a remainder comparison that can treat a nonfactor as a divisor, and the Scala recursive base case returns `[1]` for input `1`. The shared contract below makes the common intended operation precise.

## Contract

- Input is a signed 64-bit integer `n` from 1 through 2,147,483,647.
- Return the prime factors in ascending order, retaining multiplicity, as comma-separated ASCII bytes. For example, `100` returns `2,2,5,5`.
- Return an empty byte sequence for `n = 1`.
- Return `-1` outside the supported input range.
- Return `-2` when the output buffer is too small; do not write to the buffer in that case.
- At this input bound, the longest result is at most 59 bytes, within the 63-byte scalar byte-output ABI limit.

All nine portable ports use integer trial division and avoid floating-point square roots and architecture-specific instructions.

## Workload and verification

[`workload.json`](workload.json) covers primes, repeated factors, composites, the largest signed-32-bit input, the empty factorization for one, and invalid signed values. [`benchmarks/verify_prime_factors.py`](../../verify_prime_factors.py) checks every input from 1 through 2,048, deterministic random values, factor powers, boundary inputs, and insufficient output capacities against an independent trial-division oracle. All nine languages passed 5,143 oracle cases and 17 workload cases each.

## Upstream sources

- [TheAlgorithms/JavaScript PrimeFactors.js](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/PrimeFactors.js)
- [TheAlgorithms/Julia prime_factors.jl](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/prime_factors.jl)
- [TheAlgorithms/Python prime_factors.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/prime_factors.py)
- [TheAlgorithms/Rust prime_factors.rs](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/prime_factors.rs)
- [TheAlgorithms/Scala PrimeFactors.scala](https://github.com/TheAlgorithms/Scala/blob/de555349d5effb87962d3116eb08c9f374065112/src/main/scala/Mathematics/PrimeFactors.scala)

# Liouville function

The pinned Python source defines Liouville's function by counting prime factors with multiplicity. This benchmark keeps that definition and uses integer trial division in all nine portable ports.

## Contract

- Input is a signed 64-bit integer `n` from 1 through 2,147,483,647.
- Return `(-1)^Ω(n)`, where `Ω(n)` is the total number of prime factors counting multiplicity.
- Return `-1` outside the supported input range.
- `λ(1) = 1` because 1 has no prime factors.

For example, `λ(4) = 1` because `4 = 2×2` has two prime factors with multiplicity. This distinguishes Liouville's function from the Möbius function, which returns zero for nonsquarefree inputs such as 4.

The input range matches the repository's `prime_factors` benchmark. Each implementation uses overflow-safe integer trial division (`factor <= remaining / factor`) and toggles the sign for every occurrence of a factor.

## Workload

[`workload.json`](workload.json) includes 1, prime and composite inputs, repeated prime factors, a large prime, the upper bound, and values outside the supported range.

## Upstream sources

- [TheAlgorithms/Python liouville_lambda.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/liouville_lambda.py)
- [TheAlgorithms/Python prime_factors.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/prime_factors.py)

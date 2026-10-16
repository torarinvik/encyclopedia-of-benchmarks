# Project Euler Problem 51: Prime digit replacements

## Contract

The benchmark captures the pinned Python `solution()` no-argument call, which uses its default family length of eight. The scalar ABI accepts zero as an ignored placeholder; nonzero values return `-1`. The source searches primes below 1,000,000, retaining only primes for which `digit_count - distinct_digit_count >= 3`. For each repeated digit, it replaces all occurrences with each decimal digit and counts only family members that also pass this filtered-prime test. The first family with exactly eight members returns its smallest prime, `121,313`.

The source iterates a Python `set` of filtered primes, so results for its non-default family-length examples depend on set iteration order. This workload therefore pins the canonical default call. The ports scan candidates in ascending numeric order, preserve the source's replacement and family filters, and return the same canonical result.

## Workload

[`workload.json`](workload.json) covers the fixed default search and positive and negative invalid placeholders. The prime sieve uses the source's strict upper bound: values are less than 1,000,000.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_051/sol1.py) sieves primes below one million, filters by repeated digits, replaces every occurrence of one repeated digit, and returns the minimum prime from the first matching family.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem51.c](../../../c/p/problem51.c) |
| C3 | [c3/p/problem51.c3](../../../c3/p/problem51.c3) |
| C++ | [cpp/p/problem51.cpp](../../../cpp/p/problem51.cpp) |
| Elisa | [elisa/p/problem51.elisa](../../../elisa/p/problem51.elisa) |
| Nim | [nim/p/problem51.nim](../../../nim/p/problem51.nim) |
| Odin | [odin/p/problem51.odin](../../../odin/p/problem51.odin) |
| Rust | [rust/p/problem51.rs](../../../rust/p/problem51.rs) |
| V | [v/p/problem51.v](../../../v/p/problem51.v) |
| Zig | [zig/p/problem51.zig](../../../zig/p/problem51.zig) |

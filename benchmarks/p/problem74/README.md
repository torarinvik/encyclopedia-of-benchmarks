# Project Euler Problem 74: Digit factorial chains

## Contract

The pinned Python source scans starting values from 1 through max_start - 1, in ascending order, and counts those whose memoized chain length equals num_terms. The upper bound is exclusive. Its default call uses 60 terms and max_start 1,000,000, returning 402.

The source sums decimal digit factorials and uses a recursive previous-term set to stop at a repeated term. It also starts with a fixed chain-length cache, including 145 mapped to length 0, 169/1454/36301 mapped to 3, and 871/872/45361 mapped to 2. The ports preserve these initial cache entries and the ascending start order; cache values are stored as length plus one so zero remains the empty marker.

The binary-scalar input is [num_terms, max_start]. Any signed num_terms is compared as given; max_start values above 1,000,000 return -1, while max_start at or below 1 yields the source's empty-range result 0. Starting values below one million and their digit-factorial successors stay at or below 2,540,160, which bounds the compact cache table.

The source example solution(10, 1000) returns 28.

## Workload

The [workload JSON](workload.json) covers the default, the documented example, exclusive upper-bound behavior, the seeded zero-length cache entry, empty ranges, and an out-of-bound maximum start.

## TheAlgorithms reference

- Python [sol1.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_074/sol1.py) sums digit factorials, memoizes chain lengths, and counts matching starts below the exclusive max_start.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem74.c](../../../c/p/problem74.c) |
| C3 | [c3/p/problem74.c3](../../../c3/p/problem74.c3) |
| C++ | [cpp/p/problem74.cpp](../../../cpp/p/problem74.cpp) |
| Elisa | [elisa/p/problem74.elisa](../../../elisa/p/problem74.elisa) |
| Nim | [nim/p/problem74.nim](../../../nim/p/problem74.nim) |
| Odin | [odin/p/problem74.odin](../../../odin/p/problem74.odin) |
| Rust | [rust/p/problem74.rs](../../../rust/p/problem74.rs) |
| V | [v/p/problem74.v](../../../v/p/problem74.v) |
| Zig | [zig/p/problem74.zig](../../../zig/p/problem74.zig) |

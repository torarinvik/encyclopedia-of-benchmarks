# Taxicab minimum representations

This scalar benchmark returns Taxicab(k), the least positive integer expressible as a sum of two positive integer cubes in `k` distinct unordered ways, for `k=2` or `k=3`.

## Contract

- ABI: `i64_array_scalar`; exported symbol: `taxicab_number_minimum_representations`.
- Input is exactly `[k]`, where `k` is 2 or 3. The parser accepts at most two i64 words so a trailing word is rejected. Null, empty, trailing, or out-of-domain input returns `-1`.
- Each representation is a pair `(a,b)` with `1<=a<=b`; equal roots are permitted and count as one unordered pair.
- Output is the least sum with at least `k` distinct pairs. The expected values are Taxicab(2)=1,729 and Taxicab(3)=87,539,319.
- The primary merges the 444 strictly increasing rows `a^3+b^3`, for each `a=1..444` and `b=a..444`, using a binary min-heap. It drains each equal-sum group before returning, advances every popped row to its next `b`, and returns the first group whose multiplicity reaches `k`.
- The root cap is exhaustive for both outputs: Boyer gives Taxicab(3)=87,539,319, while `445^3=88,121,125` is larger. Thus no positive root in a sum at or below the largest requested result can exceed 444.
- At most `444*445/2=98,790` pairs are processed. The primary uses `O(P log 444)` time and a fixed 444-node heap. Each node is three i32 values, so the heap occupies 5,328 bytes; the declared 8,192-byte workspace cap includes the heap and scalar state. Each pair sum is at most `2*444^3=175,056,768`, which fits signed i32; the exported result is widened to i64.
- The independent oracle materializes and sorts all 98,790 i64 pair sums, then scans equal-value runs. The packed signed-64 payload is 790,320 bytes before Python list and integer-object overhead; that oracle is not part of the native primary workspace cap.

This algorithm differs from primality/factorization profiles and from signed-cube Cabtaxi enumeration. It finds the earliest collision among monotonically increasing pair-sum rows.

## Sources and provenance

Christian Boyer defines Taxicab(n) as the least integer expressible in `n` ways as a sum of two positive integer cubes and gives the first values and decompositions in “New Upper Bounds for Taxicab and Cabtaxi Numbers,” *Journal of Integer Sequences* 11 (2008), Article 08.1.6 ([primary article](https://cs.uwaterloo.ca/journals/JIS/VOL11/Boyer/boyer.html)). The [RosettaCodeData popular-tasks title index](https://raw.githubusercontent.com/acmeism/RosettaCodeData/main/popular-tasks) was used only to discover the benchmark title. No Rosetta task text, source code, examples, or fixtures are reused. The profile, ports, references, and workload are clean-room work.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/t/taxicab_number_minimum_representations.c`](../../../c/t/taxicab_number_minimum_representations.c) |
| C3 | [`c3/t/taxicab_number_minimum_representations.c3`](../../../c3/t/taxicab_number_minimum_representations.c3) |
| C++ | [`cpp/t/taxicab_number_minimum_representations.cpp`](../../../cpp/t/taxicab_number_minimum_representations.cpp) |
| Elisa | [`elisa/t/taxicab_number_minimum_representations.elisa`](../../../elisa/t/taxicab_number_minimum_representations.elisa) |
| Mojo | [`mojo/t/taxicab_number_minimum_representations.mojo`](../../../mojo/t/taxicab_number_minimum_representations.mojo) |
| Nim | [`nim/t/taxicab_number_minimum_representations.nim`](../../../nim/t/taxicab_number_minimum_representations.nim) |
| Odin | [`odin/t/taxicab_number_minimum_representations.odin`](../../../odin/t/taxicab_number_minimum_representations.odin) |
| Rust | [`rust/t/taxicab_number_minimum_representations.rs`](../../../rust/t/taxicab_number_minimum_representations.rs) |
| V | [`v/t/taxicab_number_minimum_representations.v`](../../../v/t/taxicab_number_minimum_representations.v) |
| Zig | [`zig/t/taxicab_number_minimum_representations.zig`](../../../zig/t/taxicab_number_minimum_representations.zig) |

`primary_oracle.py` implements the heap merge; `independent_oracle.py` uses materialize-sort-group enumeration. `verify_workload.py` states the workload/oracle reconciliation, and `check_inventory.py` statically pins package artifacts and ten exported source paths. No executable validation was run.

The scalar runner and verifier plus README and CATALOG registration are
integrated; no programs, tests, scripts, checkers, builds, compilers, profilers,
or benchmarks were run.

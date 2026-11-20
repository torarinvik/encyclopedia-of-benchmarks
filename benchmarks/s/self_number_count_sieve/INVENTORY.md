# Package inventory

Algorithm: `self_number_count_sieve`  
ABI: `i64_array_scalar`  
Input: `[N]`, `1 <= N <= 100000`  
Output: number of positive self-numbers in the inclusive interval `[1,N]`  
Workspace cap: 16,384 bytes

## Native ports

- `c/s/self_number_count_sieve.c`
- `cpp/s/self_number_count_sieve.cpp`
- `rust/s/self_number_count_sieve.rs`
- `elisa/s/self_number_count_sieve.elisa`
- `c3/s/self_number_count_sieve.c3`
- `nim/s/self_number_count_sieve.nim`
- `odin/s/self_number_count_sieve.odin`
- `v/s/self_number_count_sieve.v`
- `zig/s/self_number_count_sieve.zig`
- `mojo/s/self_number_count_sieve.mojo`

## Package artifacts

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`, `__init__.py`
- `workload.json`
- `primary_oracle.py`, `independent_oracle.py`
- `verify_workload.py`, `check_inventory.py`

The title-band comparison found the sieve of Sundaram, shortest common supersequence, Kolakoski, longest substring without repeating characters, matrix-chain multiplication, word ladder, Pisano period, N-body, and image convolution already represented by local contracts. No local self-number definition/count contract was found. The adjacent `lucky_number_sieve` and divisor-count sieve use different generation rules.

The primary stores generated values in 1,563 `uint64` words, enough for positions 0 through 100,000 (12,504 bytes). It visits each source through N, marks `x + digit_sum10(x)` when the target is in range, then counts unmarked positions from 1 through N. The independent method checks each candidate y against all positive possible generators in `[max(1, y-9*d), y-1]`, where d is the decimal digit count of y. Native explicit scratch is 12,504 bytes plus scalar locals; the package allows 16,384 bytes. Published count checkpoints through 1,000, 10,000, and 100,000 are 102, 983, and 9,784.

Sources: [MathWorld's self-number definition](https://mathworld.wolfram.com/SelfNumber.html), the [CMU ACM problem statement](https://www.cs.cmu.edu/~eugene/teach/acm03/prob/self.html), [OEIS A003052](https://oeis.org/A003052) and its [b-file](https://oeis.org/A003052/b003052.txt), [OEIS A282711](https://oeis.org/A282711), the [published count cross-check](https://www.primepuzzles.net/puzzles/puzz_373.htm), and the pinned [RosettaCodeData title index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks). The title index was used for discovery only.

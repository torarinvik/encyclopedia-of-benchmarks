# Zhouge summatory multiplicative function

This benchmark uses the Zhouge sieve to compute
`sum(f(n), 1 <= n <= N) mod 469762049` for the multiplicative family
`f(p^e) = a*e + b*p mod 469762049`.

The repository also contains [`sum_of_multiplicative_function_large`](../sum_of_multiplicative_function_large/README.md), which uses Min_25 for this same function family. This package profiles the distinct Zhouge sieve algorithm.

## Contract

- Input is a three-element signed 64-bit array `[N, a, b]`; exactly three
  values are valid and up to four are parseable.
- Require `1 <= N <= 10,000,000` and `0 <= a,b < 469762049`. Invalid input
  returns `-1`.
- `f(1)=1`; values on coprime arguments multiply, and the prime-power rule is
  applied modulo `469762049`.
- Output is the summatory value modulo `469762049`.
- Declared workspace is at most `344,064` bytes.

## Method and state invariant

The implementation stores the distinct quotient values `floor(N/i)` in their
implicit two-part index layout. For `s=0` and `s=1`, the `G_s(y)` state begins
as `sum(x^s, 1 <= x <= y)`. After sieving a prefix of the small primes, it is
the corresponding power sum over integers with no prime factor from that
prefix. A prime `p` updates a state with `y >= p^2` by subtracting
`p^s * G_s(floor(y/p))`. If `p^2 > y`, the only affected integer is the prime
`p` itself; a per-state cursor defers that single-prime subtraction and
applies it from prefix sums before a child state is read and at the final
flush. This leaves `1` and the primes above `sqrt(N)` in each finished state.

During the descending-prime phase, `D_t(y)` sums `f(x)` over values whose
prime factors are drawn from `p_t, ..., p_m`. The empty suffix boundary is
`D_{m+1}(y)=1`.
Its recurrence is
`D_t(y)=D_{t+1}(y)+sum_{e>=1,p_t^e<=y} f(p_t^e)*D_{t+1}(floor(y/p_t^e))`.
Each stage enumerates every power `p_t^e` from `e=1` through the last exponent
with `p_t^e<=y`, and uses the exact local value `a*e+b*p_t`; thus every
small-prime prime-power term is represented.
When `p_t^2 > y`, only the single-prime term can contribute. A second cursor
defers those terms and uses the prefix sums of `f(p)` before a state is read.
After all primes up to `sqrt(N)` are processed, `D(N)` sums exactly the values
whose prime factors are all at most `sqrt(N)`. The final answer is

`D(N) + sum_{u <= sqrt(N)} f(u) * (a*(G_0(floor(N/u))-1) + b*(G_1(floor(N/u))-1))`.

Every input integer is counted once: either all its prime factors are at most
`sqrt(N)`, or it has one prime factor above `sqrt(N)`. Quotient compression
gives `O(sqrt(N))` states. Prefix-corrected updates skip the single-prime tail
for each state, giving `O(N^(3/4)/log N)` time and `O(sqrt(N))` space.

## Workspace accounting

At `N=10,000,000`, `root=floor(sqrt(N))=3162` and the quotient layout has at
most 6,324 states. The conservative byte ledger uses the maximum root-sized
capacity for the prime list and both prefix arrays:

| Buffers | Calculation | Bytes |
|---|---:|---:|
| `G_0`, `G_1`, `D` (`i64`) | `3 * 6,324 * 8` | 151,776 |
| two prime bounds and two lazy cursors (`u32`) | `4 * 6,324 * 4` | 101,184 |
| smallest-prime-factor table (`u32`) | `3,163 * 4` | 12,652 |
| prime list (`i64`) | `3,163 * 8` | 25,304 |
| prime-sum and `f(p)` prefix tables (`i64`) | `2 * 3,163 * 8` | 50,608 |
| **Conservative buffer total** |  | **341,524** |

The 344,064-byte declared cap leaves 2,540 bytes for allocator alignment and
small container descriptors. No quotient-value array is stored; each value is
recovered from its index. The direct segmented oracle is verification-only and
is not included in benchmark workspace.

## References and clean-room scope

- [OI Wiki: Zhouge sieve](https://oi-wiki.org/math/number-theory/zhou/)
- [Ren Zhizhou, “Several Methods for Summing Multiplicative Functions,” 2016
  Chinese National Olympiad in Informatics training-team paper collection
  (PDF)](https://yutong.site/wp-content/uploads/2018/09/%E5%9B%BD%E5%AE%B6%E9%9B%86%E8%AE%AD%E9%98%9F2016%E8%AE%BA%E6%96%87%E9%9B%86.pdf)

The ports implement the algorithm and recurrence in original code. The
independent oracle uses segmented prime factorization, rather than Zhouge sieve
states. No source code, prose, examples, or test data were copied.

## Implementations

All ten ports use the `i64_array_scalar` ABI:

| Language | Source |
|---|---|
| C | `c/s/zhouge_summatory_multiplicative_function.c` |
| C3 | `c3/s/zhouge_summatory_multiplicative_function.c3` |
| C++ | `cpp/s/zhouge_summatory_multiplicative_function.cpp` |
| Elisa | `elisa/s/zhouge_summatory_multiplicative_function.elisa` |
| Mojo | `mojo/s/zhouge_summatory_multiplicative_function.mojo` |
| Nim | `nim/s/zhouge_summatory_multiplicative_function.nim` |
| Odin | `odin/s/zhouge_summatory_multiplicative_function.odin` |
| Rust | `rust/s/zhouge_summatory_multiplicative_function.rs` |
| V | `v/s/zhouge_summatory_multiplicative_function.v` |
| Zig | `zig/s/zhouge_summatory_multiplicative_function.zig` |

`primary_oracle.py` uses the same optimized sieve structure for fixture
validation. `independent_oracle.py` factors values directly in bounded
segments.

# MallocBench CFrac bounded factorization profile

The pinned launcher exercises Morrison–Brillhart continued-fraction factorization (CFRAC), with Pomerance's early-abort strategy and a search for a multiplier/factor-base size. This package keeps the defining CFRAC path: generate convergents and their denominator norms, collect smooth relations over a quadratic-residue factor base, eliminate relation parity vectors over GF(2), and use the resulting square congruence to obtain a factor through `gcd(x-y,n)` or `gcd(x+y,n)`.

## Contract

- ABI: `i64_array_scalar`, symbol `mallocbench_cfrac`.
- Input is exactly `[n, factor_base_count, iteration_limit]`.
- `n` must be odd, non-square, and in `[15, 1_000_000]`. The factor base count is `[2,10]`; the iteration limit is `[1,48]`.
- The profile fixes multiplier `k=1` and follows the source factor-base order: include 2, then scan odd primes and select Legendre residues 0 or 1 until the requested count is reached. The source selects residue 0 as well as 1; because residue 0 means `p` divides `n`, this bounded profile rejects that case as a domain precondition rather than adding the divisor to the base. Primes scanned after the requested base is full are not checked. This keeps the source routine's documented precondition that trial division removed factor-base divisors.
- The loop retains the source recurrence with `g=floor(sqrt(n))`, `u=U=2g`, `Q=1`, `Qprev=n-g²`, `A=1`, `Aprev=g`, and initial quotient `q=0`. Each step applies `A=(q*A+Aprev) mod n`, `Q=q*(U-u)+Qprev`, then obtains `(q,r)` from `u/Q` when `u-Q>=Q` (otherwise uses `q=1,r=u-Q`) and sets `u=2g-r`. The sign parity toggles each step.
- Fully factor-base-smooth `Q` values add one relation. Its parity vector contains the sign bit and each factor-base exponent modulo two. A dependency yields `x` as the product of selected `A` residues and `y` from half the summed prime exponents; the implementation returns a proper gcd factor when found.
- Partial relations, Pomerance early aborts, multiplier search, and the source's arbitrary-precision arithmetic are omitted. The bounded `n` domain ensures the recurrence and modular products fit signed/unsigned 64-bit arithmetic. If no factor is found by the limit, return `n`, matching the source's failure result. Invalid input returns `-1`.

The full factorization path remains data dependent: if a norm is not fully smooth, it contributes no relation. The iteration limit counts recurrence steps, not only smooth relations. The source's large 35- and 39-digit launch inputs are outside this portable profile.

## Workload and oracle

[`workload.json`](workload.json) contains the hand-derived `n=91` relation case, a shorter bound that returns the original input, and invalid-domain cases. [`mallocbench_cfrac_oracle.py`](../../mallocbench_cfrac_oracle.py) uses Python integers, `math.isqrt`, and a dictionary-based GF(2) basis to compute bounded results independently.

## Provenance and rights

Source: [lac-dcc/Benchmarks `MallocBench/cfrac`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MallocBench/cfrac), pinned at `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher calls `pcfrac`; the source comments identify Morrison and Brillhart's algorithm, Pomerance early aborts, and Knuth's multiplier selection. `pcfrac.c` credits Dave Barrett. Its bundled `precision.h` identifies David A. Barrett (1991) and says that library is not to be used for profit or distributed in systems sold for profit.

The local implementations are independent bounded arithmetic implementations of the CFRAC recurrence and relation method. They do not copy, include, link, or translate the restricted arbitrary-precision package. This provenance note does not claim a license for that package or for the original source code; consult the upstream notices before redistributing upstream files.

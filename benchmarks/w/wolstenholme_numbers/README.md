# Wolstenholme numbers

For each integer `n` from 1 through 22, this benchmark returns the reduced numerator of the generalized harmonic number

`H_n^(2) = 1 + 1/2^2 + 1/3^2 + ... + 1/n^2`.

The scalar `i64_array_scalar` ABI accepts exactly one signed 64-bit word, `[n]`. Invalid or null input returns `-1`. Valid output is the numerator after the fraction has been reduced to lowest terms; the denominator is not returned.

## Bounds and algorithms

The primary reference and language ports accumulate a reduced fraction. When adding `1/k^2` to `a/b`, they first cancel `g=gcd(b,k^2)`, form `a*(k^2/g) + b/g` over `b*(k^2/g)`, then reduce the new numerator and denominator by their gcd. This cross-cancellation keeps each denominator at most `L=lcm(1^2,...,22^2)=232792560^2=54192375991353600`.

Since `H_n^(2)<2`, each pre-reduction numerator is less than `2L=108384751982707200`, below signed 64-bit maximum. The largest returned numerator among the supported inputs is `86364397717734821` at `n=19`. The ports use constant scalar state; the declared workspace cap is 256 bytes. The independent reference instead constructs the common denominator `L`, sums `L/k^2`, and reduces once at the end. The workload's largest valid and parseable inputs are 1 and 2 words respectively; the largest scalar result occupies one i64.

## Sources and distinctness

The mathematical definition and term values are cross-referenced with [MathWorld's Wolstenholme Number entry](https://mathworld.wolfram.com/WolstenholmeNumber.html) and [OEIS A007406](https://oeis.org/A007406), which identifies these as numerators of `H_n^(2)`. These sources provide mathematical facts and pinned outputs only; the implementations and fixtures were written independently. See [`RIGHTS.md`](RIGHTS.md).

This profile computes the exact reduced numerator for a bounded parameter. It differs from [`harmonic_series`](../../h/harmonic_series/README.md), which emits the individual terms `1/k`, and [`sum_of_harmonic_series`](../../s/sum_of_harmonic_series/README.md), which sums binary64 reciprocals along an arithmetic progression; neither returns this exact sequence of reduced numerators.

## Package artifacts

The two references are [`primary_oracle.py`](primary_oracle.py) and [`independent_oracle.py`](independent_oracle.py). [`workload.json`](workload.json) pins all 22 supported values plus malformed-input cases. [`INVENTORY.md`](INVENTORY.md), [`INVENTORY.json`](INVENTORY.json), [`check_inventory.py`](check_inventory.py), and [`verify_workload.py`](verify_workload.py) describe the static package contents. The package is registered in the shared scalar runner and verifier; these tools were not run.

## Language ports

| Language | Source |
|---|---|
| C | [`c/w/wolstenholme_numbers.c`](../../../c/w/wolstenholme_numbers.c) |
| C3 | [`c3/w/wolstenholme_numbers.c3`](../../../c3/w/wolstenholme_numbers.c3) |
| C++ | [`cpp/w/wolstenholme_numbers.cpp`](../../../cpp/w/wolstenholme_numbers.cpp) |
| Elisa | [`elisa/w/wolstenholme_numbers.elisa`](../../../elisa/w/wolstenholme_numbers.elisa) |
| Mojo | [`mojo/w/wolstenholme_numbers.mojo`](../../../mojo/w/wolstenholme_numbers.mojo) |
| Nim | [`nim/w/wolstenholme_numbers.nim`](../../../nim/w/wolstenholme_numbers.nim) |
| Odin | [`odin/w/wolstenholme_numbers.odin`](../../../odin/w/wolstenholme_numbers.odin) |
| Rust | [`rust/w/wolstenholme_numbers.rs`](../../../rust/w/wolstenholme_numbers.rs) |
| V | [`v/w/wolstenholme_numbers.v`](../../../v/w/wolstenholme_numbers.v) |
| Zig | [`zig/w/wolstenholme_numbers.zig`](../../../zig/w/wolstenholme_numbers.zig) |

All artifacts received source-only review. No programs or validation helpers were run.

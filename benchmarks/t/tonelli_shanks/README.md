# Tonelli–Shanks

This benchmark returns the least nonnegative square root of a residue modulo an odd prime. It preserves the pinned Python implementation's zero-residue handling, `p ≡ 3 (mod 4)` shortcut, and full Tonelli–Shanks update sequence for other odd primes.

## Contract

- The read-only signed 64-bit input is exactly `[residue, prime]`.
- The caller must provide an odd prime from 3 through 1,000,003 and a residue from 0 through `prime - 1`. Primality is a source precondition; the source checks only that the modulus is odd and greater than two, and the ports do not add primality testing.
- The result is the smaller of the two nonnegative square roots modulo `prime`. Residue zero returns zero. A quadratic nonresidue maps the source's `ValueError` to `-1`.
- Wrong packed length, residue outside the stated range, even/too-small modulus, or modulus above the bound returns `-1`.

The source's `p ≡ 3 (mod 4)` path computes one modular exponentiation. For `p ≡ 1 (mod 4)`, it factors `p - 1 = q·2^s`, chooses the first quadratic nonresidue starting at 2, and performs the standard Tonelli–Shanks updates. The benchmark uses only known prime moduli in its workload.

## Workload

[`workload.json`](workload.json) covers both algorithm paths, the zero residue, two-root minimization, nonresidues, and invalid packed domains.

The shared scalar-array runner preserves the zero-residue branch, the `p ≡ 3 (mod 4)` shortcut, and the bounded Tonelli–Shanks sequence for the workload oracle.

## Reviewed source

- [Python `tonelli_shanks.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/tonelli_shanks.py) — `tonelli_shanks` and its Legendre-symbol helper.

## Implementations

The nine portable ports use the shared `i64_array_scalar` ABI. Their source files are in the `t` folder for each language.

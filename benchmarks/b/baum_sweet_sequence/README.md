# Baum–Sweet sequence prefixes

Pack the first `count` terms of OEIS A086747 into one signed 64-bit result.
This is a deterministic finite-automaton benchmark over the binary expansions
of consecutive indices.

## Contract

- Input is exactly one signed 64-bit integer `[count]`, with `0 <= count <= 63`;
  a two-word frame is parseable only to reject its extra value.
- For each index `n` in `0..count`, compute the OEIS A086747 term: it is `1`
  exactly when the binary representation of `n` has no odd-length run of zero
  bits; otherwise it is `0`. The representation of zero is the one-bit string
  `"0"`, so `a(0)=0` and the first terms are `0,1,0,1,1,0,0,1,...`.
- Pack `a(n)` into result bit `n`, with `a(0)` in the least significant bit.
  For `count=0`, return zero. At the maximum count of 63, only bits 0 through
  62 are used, so every valid result is a nonnegative signed 64-bit integer.
- Missing, null, extra, negative, or greater-than-63 input is invalid and
  returns `-1`.
- The primary port scans each index from its highest set bit to its lowest,
  tracking the parity of the current zero run in a two-state automaton; a
  third rejecting state is implicit. The independent oracle converts each
  index to binary text and scans complete zero runs. Both take O(count log
  count) time overall and O(1) auxiliary space.

The OEIS A086747 convention is explicit here because some presentations of
the Baum–Sweet word set the term at index zero to one. This package follows
A086747's listed terms and treats the ordinary binary representation of zero
as `"0"`.

## Provenance

- [OEIS A086747](https://oeis.org/A086747) records the defining zero-run
  property and sequence values.
- Allouche and Shallit describe the sequence as 2-automatic in
  [*Automatic Sequences: Theory, Applications, Generalizations*](https://doi.org/10.1017/CBO9780511546563),
  Cambridge University Press, 2003.
- Baum and Sweet's original paper is [“Continued Fractions of Algebraic Power
  Series in Characteristic 2”](https://doi.org/10.2307/1970953), *Annals of
  Mathematics* 103(3), 593–610 (1976).

The bounded contract, automaton implementation, independent run-scanning
oracle, fixtures, and ten ports are clean-room work. The `i64_array_scalar`
runner and verifier have package dispatch and workload checks registered; no
executable validation has been run. No source code or prose is copied. See
[RIGHTS.md](RIGHTS.md), [workload.json](workload.json), and
[INVENTORY.md](INVENTORY.md).

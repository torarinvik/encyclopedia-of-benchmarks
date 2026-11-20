# Lucky number sieve

Generate the bounded prefix survivors of the standard lucky-number sieve, or
of its even-started variant. This is distinct from the existing
[`lucky_number`](../lucky_number/README.md) package, which preserves a pinned
rank predicate and explicitly does not implement the standard sieve.

## Contract

The exported `lucky_number_sieve` function uses the
`i64_array_bytes_output` ABI. Input is exactly `[mode, inclusive_bound]`:

- `mode = 0`: begin with the positive odd integers `1, 3, 5, ...` (OEIS
  A000959).
- `mode = 1`: begin with the positive even integers `2, 4, 6, ...` (OEIS
  A045954).
- `0 <= inclusive_bound <= 4096`.

At each round, select the current survivor at zero-based index 1, then index 2,
and so on. If its value is `step`, remove every `step`-th item from the
current sequence, counting positions from 1. Stop when there is no next
survivor or its step exceeds the current sequence length. In the finite prefix,
later step values are larger, so once a step exceeds the current length no
remaining position can be removed.

The result contains every survivor no greater than the bound, in ascending
order, encoded as consecutive little-endian signed 64-bit integers. The return
value is the number of output bytes. Malformed input returns `-1`; a null
output pointer or insufficient capacity returns `-2`. Errors leave the output
untouched. A non-null output pointer is required even when the result is empty.

The initial candidate list contains at most 2,048 values, so the fixed
candidate workspace and maximum output are each 16,384 bytes. The sieve takes
at most `O(n^2)` filtering work and `O(n)` fixed workspace for `n` initial
candidates.

## Algorithm references

The Rosetta Code task is used as an algorithm index; no task solution code or
prose is reused. The standard odd-started sieve is catalogued as
[OEIS A000959](https://oeis.org/A000959), and the even-started variant as
[OEIS A045954](https://oeis.org/A045954). See [RIGHTS.md](RIGHTS.md) for
provenance.

## Workload and implementation inventory

[`workload.json`](workload.json) records hand-checkable small prefixes, both
modes, empty output, malformed inputs, and output errors. The primary and
independent Python implementations use different sieve representations.
[`verify_workload.py`](verify_workload.py) checks fixture arithmetic, package
metadata, and the presence of all ten ports without launching them.
[`INVENTORY.md`](INVENTORY.md) lists each source path. The dedicated suite
verifier is [`benchmarks/verify_lucky_number_sieve.py`](../../verify_lucky_number_sieve.py).

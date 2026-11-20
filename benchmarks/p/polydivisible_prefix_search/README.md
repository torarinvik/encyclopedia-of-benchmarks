# Polydivisible prefix search

Count positive polydivisible numbers with up to a bounded number of digits in
one base. The search incrementally extends only prefixes that already meet
the divisibility rule.

## Contract

- Input is exactly `[base, max_digits]`, with `2 <= base <= 10` and
  `1 <= max_digits <= 6`.
- A positive base-`b` number is polydivisible when its first `j` digits, read
  as a base-`b` integer, are divisible by `j` for every prefix length `j`.
  Leading zeroes are not allowed. The profile counts all qualifying numbers
  whose lengths are from 1 through `max_digits`.
- Start with each one-digit prefix `1..base-1`. To extend a valid prefix value
  `p` of length `j`, try `base*p+d` for each digit `d` from 0 through `base-1`;
  recurse only when the candidate is divisible by `j+1`. Return the number of
  valid prefixes visited. Malformed input returns `-1`.
- The search depth is at most six. At base ten, its worst-case candidate tree
  contains fewer than one million prefixes and fewer than one million
  extension attempts; the recursion stack is bounded by six levels. This
  intentionally bounded profile measures incremental extension and pruning,
  rather than enumerating the full polydivisible sequence. The known
  25-digit decimal maximum from the Stanford exercise is outside this
  benchmark's domain.

The profile excludes zero although some sequence listings include it as a
special initial term: this contract generates positive numbers with a
nonzero leading digit.

## References

- [OEIS A397953](https://oeis.org/A397953) states the prefix-divisibility
  definition for base three and gives hand-checkable terms.
- Stanford's [CS106AX midterm polydivisible-number problem](https://web.stanford.edu/class/archive/cs/cs106ax/cs106ax.1252/res/handouts/16-CS106AX-Midterm)
  describes extending each accepted prefix by one base digit and retaining
  only divisible extensions. The package ports independently implement that
  procedure for bases 2 through 10 and a six-digit cap.
- The [Codewars Algorithms index](https://www.codewars.com/kata/latest?tags=Algorithms)
  was used only as a title-discovery lead.

The workload, two references, ports, and contract are clean-room artifacts;
no third-party code or prose is copied. The `i64_array_scalar` runner and
verifier dispatch and workload checks are registered in source; no executable
validation has been run. See [RIGHTS.md](RIGHTS.md), [workload.json](workload.json),
and [INVENTORY.md](INVENTORY.md).

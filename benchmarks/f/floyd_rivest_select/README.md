# Floyd–Rivest SELECT

Floyd–Rivest SELECT estimates a pivot by recursively selecting the requested
rank inside a narrow, rank-centered sample window. That estimator is the key
difference from the repository's median-of-three quickselect and groups-of-five
median-of-medians profiles.

## Contract

- `i64_array_scalar` input is `[n, k, value_0, ..., value_(n-1)]`.
- `1 <= n <= 64`, `0 <= k < n`, and values are distinct integers in
  `[0, 2^31-1]`. The array must have exactly `n+2` words.
- Return the value at zero-based sorted rank `k`; return `-1` on invalid input.
- The bounded profile enters the sample-window branch when the active inclusive
  range has `R-L > 24`. The original Algorithm 489 listing uses 600; its paper
  notes that this cutoff was machine tuned. The smaller profile cutoff lets the
  workload cover both branches with short, portable fixtures.
- Compute the paper's rank-centered estimates with binary64 arithmetic, round
  the lower endpoint down and the upper endpoint up, then clamp the window to
  the active range and requested rank. Select the same absolute rank recursively
  in that window. Partition the active range into less/equal/greater regions
  around its selected pivot and continue into the region containing `k`.
- The local array copy keeps the shared read-only input unchanged. The bounded
  implementation has O(n²) worst-case time and O(n) auxiliary space.

## Workload

`workload.json` covers the cutoff on either side, extreme and middle ranks,
invalid framing, duplicate rejection, and value bounds. The primary oracle uses
the rank-centered estimator and three-way partition; the independent oracle
sorts a separate copy. No random generator is involved.

## References

- Floyd and Rivest, [Algorithm 489](https://doi.org/10.1145/360680.360694).
- Floyd and Rivest, [Expected Time Bounds for Selection](https://people.csail.mit.edu/rivest/pubs/FR75a.pdf).
- The existing [quickselect](../../q/quick_select/README.md) and
  [median-of-medians](../../m/median_of_medians/README.md) packages use different
  pivot strategies.

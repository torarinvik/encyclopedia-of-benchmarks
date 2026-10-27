# Optimistic Rate-Based Flow-Control Updates

This package implements the update operation and four scheduler policies
described in “Schedulers for Optimistic Rate Based Flow Control,” Panagiota
Fatourou, *Encyclopedia of Algorithms*, DOI
10.1007/978-1-4939-2864-4_356: RoundRobin, GlobalMin, LocalMin, and Linear.
It returns the exact rates after a bounded number of update operations. It
does not claim that the trace has converged or measure the chapter's
asymptotic convergence bounds.

## Contract

The ABI is `i64_array_bytes_output`. Input is
`[sessions, links, mode, update_count, capacities[links], incidence[sessions][links]]`.
There are 2–3 sessions, 1–4 links, capacities 1–16, and 1–6 update
operations. Every session uses at least one link. All rates start at zero.
The maximum input is 20 signed 64-bit values.

Mode 0 applies sessions in repeated ID order (RoundRobin). Mode 1 selects the
globally minimum-rate session (GlobalMin). Mode 2 selects the lowest-ID local
minimum under the session overlap graph (LocalMin), comparing equal rates by
ID. Mode 3 selects the lowest-ID session on the most utilized nonempty link
(Linear); utilization ties use lower link ID. These tie rules make the
chapter's scheduler choices deterministic.

For updated session `i` and each link `e` on its path, the profile finds the
largest new rate `x` satisfying `x + sum(min(rate[j], x)) <= capacity[e]` for
the other sessions on that link. It applies the smallest such `x` across
`i`'s links, breaking equal bottlenecks by link ID, and reduces rates above
`x` on the limiting link to `x`. The exact output is a reduced numerator and
positive denominator pair per session, in session-ID order. It is at most 48
bytes. Invalid input returns `-1`; a null or undersized output returns `-2`
without writing output.

The implementation uses a bounded common denominator that preserves exact
rational rates for at most three sessions and six updates; outputs are reduced
fractions. This profile is distinct from static max-min allocation and from
max-min widest-path graph algorithms.

## Files

The nine ports are under `c/s`, `cpp/s`, `rust/s`, `c3/s`, `nim/s`, `odin/s`,
`elisa/s`, `v/s`, and `zig/s`. The workload, primary Fraction oracle, and
independent breakpoint verifier define the bounded trace.

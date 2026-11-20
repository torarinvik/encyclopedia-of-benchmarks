# Chapter 415 source crosswalk

| Source procedure | Package behavior | Bounded refinement |
|---|---|---|
| Platt §2.1, equations (13)–(21): feasible pair interval, curvature update, clipping, endpoint case, and threshold adjustment | `takeStep(i1,i2)` in each port and the primary reference | Linear kernel; source tolerances fixed at `0.001`; zero-curvature endpoints are scored through the full dual objective. The ABI stores the additive intercept `-b` so its score is `w·x+bias`. |
| Platt §2.2: KKT violation check and working-pair heuristics | `examineExample(i2)` checks `r2=E2*y2`, tries the maximum `|E1-E2|` gap, then non-bound and all-example fallback scans | Source-randomized scan starts become ascending input order; equal partner gaps choose the lowest input index. |
| Platt §2.5: alternate full-set and non-bound passes until the stopping condition | Main loop in all ten ports and both references | A supplied `pass_cap` bounds the call; convergence is reported only when the source stopping condition is reached before the cap. |
| Chapter 415 overview | Identifies SMO's two-variable analytic optimization and training loop | The package tests the linear binary case with a bounded integer-valued data frame. |

The local [`smo_dual_pair_update`](../smo_dual_pair_update/README.md) profile
implements only one analytic pair step with pair indices supplied by the
caller. It has no KKT selection, fallback hierarchy, or alternating training
loop. Local [`support_vector_classifier`](../support_vector_classifier/README.md)
uses projected-gradient fitting instead of SMO. The full deterministic bounded
training trace is therefore a distinct algorithm profile. No source code or
prose is reused.

Primary source: John C. Platt, [“Sequential Minimal Optimization: A Fast
Algorithm for Training Support Vector Machines,” MSR-TR-98-14 (1998)](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/tr-98-14.pdf),
§§2.1–2.5. Book source: Cristianini and Ricci, “Support Vector Machines,”
*Encyclopedia of Algorithms*, Chapter 415, DOI
[10.1007/978-1-4939-2864-4_415](https://doi.org/10.1007/978-1-4939-2864-4_415).

# Liu Hui inscribed-polygon area approximation

This benchmark evaluates the area of a regular polygon inscribed in a unit
circle, repeatedly doubling its side count as in Liu Hui's exhaustion method.
It starts from a regular hexagon and returns the final area rounded to the
nearest millionth.

## Contract

- The scalar ABI is `int64_t liu_hui_pi_approximation(const int64_t *values, size_t length)`.
- Input is exactly the one-value array `[doublings]`; a null pointer or any
  other length returns `-1`. The null-pointer fixture supplies length one.
- `doublings` must be an integer in `0..=16`; otherwise the result is `-1`.
- Begin with `N=6`, chord `s=1`, and apothem `r=sqrt(3)/2`. For every
  doubling, evaluate in this order: `h=s/2`, `s=sqrt(h*h+(1-r)*(1-r))`,
  `N=2*N`, then `r=sqrt(1-(s/2)*(s/2))`.
- The unrounded unit-circle polygon area is `A=N*s*r/2`. Return
  `floor(A*1,000,000+0.5)` as an integer number of millionths. Floating-point
  expressions are evaluated in binary64. The geometric polygon area is a
  lower bound on π before output quantization; rounding may move the encoded
  value above that bound.
- The maximum accepted input is 16 doublings (393,216 sides). The recurrence
  and final products stay finite in binary64 and the scaled output fits i64.

The primary reference follows the side/apothem recurrence. The independent
reference computes area directly from the central angle as
`(N/2)*sin(2*pi/N)`. The selected integer outputs have a wide margin from
half-millionth rounding boundaries across the supported domain.

## Distinction from local π benchmarks

This is the successive inscribed-polygon **area** method. It does not sample
points as `pi_approximation`, `pi_monte_carlo_estimation`, or `montecarlopi` do;
it does not sum the Nilakantha series; and it does not emit decimal digits as
the spigot packages do. The polygon-area operation and fixed iteration count
are the measured work.

## Sources

- Wolfram MathWorld, [Liu Hui's Exhaustion Method](https://mathworld.wolfram.com/LiuHuisExhaustionMethod.html), for the inscribed-polygon chord/apothem recurrence and area lower bounds.
- MacTutor History of Mathematics, [Liu Hui](https://mathshistory.st-andrews.ac.uk/Biographies/Liu_Hui/), for an independent historical description of polygon doubling for π approximation.
- The Trekhleb repository's [public algorithm index](https://github.com/trekhleb/javascript-algorithms#algorithms) supplied the discovery title “Liu Hui π Algorithm.” It was used for discovery only; no repository code was read or copied.

## Workload and ports

[`workload.json`](workload.json) covers the initial hexagon, the 12-, 24-,
48-, 96-, and 192-gons, the maximum iteration count, and invalid bounds.
[`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py) are source-only references.
[`check_inventory.py`](check_inventory.py) is a static source/documentation
inventory and has not been run. The scalar runner/verifier use the framed
`i64_array_scalar` protocol, including malformed empty, null, and trailing-
value cases.

| Language | Source |
| --- | --- |
| C | [`c/l/liu_hui_pi_approximation.c`](../../../c/l/liu_hui_pi_approximation.c) |
| C3 | [`c3/l/liu_hui_pi_approximation.c3`](../../../c3/l/liu_hui_pi_approximation.c3) |
| C++ | [`cpp/l/liu_hui_pi_approximation.cpp`](../../../cpp/l/liu_hui_pi_approximation.cpp) |
| Elisa | [`elisa/l/liu_hui_pi_approximation.elisa`](../../../elisa/l/liu_hui_pi_approximation.elisa) |
| Mojo | [`mojo/l/liu_hui_pi_approximation.mojo`](../../../mojo/l/liu_hui_pi_approximation.mojo) |
| Nim | [`nim/l/liu_hui_pi_approximation.nim`](../../../nim/l/liu_hui_pi_approximation.nim) |
| Odin | [`odin/l/liu_hui_pi_approximation.odin`](../../../odin/l/liu_hui_pi_approximation.odin) |
| Rust | [`rust/l/liu_hui_pi_approximation.rs`](../../../rust/l/liu_hui_pi_approximation.rs) |
| V | [`v/l/liu_hui_pi_approximation.v`](../../../v/l/liu_hui_pi_approximation.v) |
| Zig | [`zig/l/liu_hui_pi_approximation.zig`](../../../zig/l/liu_hui_pi_approximation.zig) |

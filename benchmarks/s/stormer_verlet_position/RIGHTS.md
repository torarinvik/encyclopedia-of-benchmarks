# Rights and provenance

The position-only two-step recurrence is sourced from the [Algorithm Archive
Verlet Integration chapter](https://www.algorithm-archive.org/contents/verlet_integration/verlet_integration.html),
which derives `x(t+dt)=2*x(t)-x(t-dt)+a(t)*dt²` from Taylor expansions. The
[PARSEC Facesim source metadata](https://github.com/cirosantilli/parsec-benchmark/blob/master/pkgs/apps/facesim/src/README)
also identifies Verlet position updates as part of a physics-simulation
application; it is included as application context, not as the formula source.

Only the algorithmic recurrence and high-level provenance are used. The
integer workload contract, ten implementations, references, fixtures, and
documentation were written independently. No upstream code, problem text,
test data, or prose was copied.

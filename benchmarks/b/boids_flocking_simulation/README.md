# Boids flocking simulation

This package measures a deterministic, bounded 2D integer specialization of
the local flocking model described by Craig Reynolds. It processes every
boid's local neighbors to form collision-avoidance, velocity-matching, and
flock-centering steering requests, then arbitrates those requests in priority
order. It does not model obstacles, visual occlusion, 3D flight, random
initialization, or a rendering loop.

## Contract

The ABI is `i64_array_bytes_output` with exported symbol
`boids_flocking_simulation`. Input is
`[N,steps,radius,max_speed,max_acceleration,(x,y,vx,vy)*N]`:

- `1<=N<=16`, `0<=steps<=16`, `0<=radius<=128`, `1<=max_speed<=32`, and
  `0<=max_acceleration<=8`.
- Initial positions are signed integer coordinates in `[-256,256]`; velocity
  components are in `[-32,32]`, and each initial velocity must have squared
  magnitude at most `max_speed^2`.
- A boid sees every other boid at squared Euclidean distance at most
  `radius^2`. The radius boundary is inclusive, the boid itself is excluded,
  and distinct boids at the same position are neighbors even at radius zero.
  Every neighbor has weight one; all others have weight zero.
- Separation sums unit-away directions represented at scale 256, then divides
  each component by the neighbor count toward zero. A coincident pair uses an
  antisymmetric x direction: the lower boid ID moves left, the higher ID moves
  right. Alignment is the truncation-toward-zero average neighbor velocity
  minus the current velocity. Cohesion is the truncation-toward-zero average
  neighbor position offset from the current boid.
- Each nonzero vector is capped to `max_acceleration`. If its squared length
  exceeds the cap squared, each output component is
  `trunc_zero(component*cap/ceil_sqrt(length_squared))`; a zero vector requests
  zero acceleration.
- Requests are allocated in this order: separation, alignment, cohesion.
  Each request consumes its integer `ceil_sqrt` length from the remaining
  acceleration budget. A request that exceeds the remaining budget is capped
  to that remainder and allocation stops. This preserves collision avoidance
  as the highest-priority behavior.
- Every boid reads the same old-state snapshot. Its allocated acceleration is
  added to its velocity, the result is capped to `max_speed`, then that new
  velocity is added to its position. All new states are committed together.
- `ceil_sqrt(n)` is the least integer `r>=0` with `r*r>=n`. Every signed
  division truncates toward zero. Boids and neighbors are scanned in ascending
  ID order.

Output contains each final `(x,y,vx,vy)` tuple in ascending boid ID as four
signed 32-bit little-endian integers (16 bytes per boid). Success returns the
byte count. Invalid input returns `-1`; a null or undersized output buffer
returns `-2` without writes. Input validation precedes output-buffer checks.
The largest valid frame has 69 words; 70 words are parseable for detecting an
extra trailing word. Output is at most 256 bytes.

With at most 16 boids and 16 steps, the simulation takes `O(steps*N^2)` time.
Eight fixed 16-element signed-64-bit arrays hold current and next coordinates
and velocities (1,024 bytes). The declared 1,280-byte workspace includes up to
256 bytes for scalar scratch and call frames; the output buffer is external.
Every position component remains within `256+16*32=768`, so output fits
signed 32-bit values. Pairwise squared distance is at most
`2*1536^2=4,718,592`; all vector sums and products are also far below signed
64-bit limits.

## References and distinction

The primary [array-oriented reference](../../boids_flocking_simulation_oracle.py)
uses fixed coordinate/velocity arrays. The independent
[object-scan reference](independent_reference.py) keeps each boid as a tuple and
rebuilds neighborhoods from the prior snapshot.
Both implement the pinned integer contract independently of the language
ports.

The primary method source is Reynolds, [“Flocks, Herds, and Schools: A
Distributed Behavioral Model”](https://www.red3d.com/cwr/papers/1987/SIGGRAPH87.pdf),
*Computer Graphics* 21(4), 1987. Its local behaviors are collision avoidance,
velocity matching, and flock centering; its arbitration section prioritizes
acceleration requests and trims the last request to the remaining budget. The
bounded profile uses those behaviors and the priority model with explicit
integer rules. The Rosetta Code [“Boids” title](https://rosettacode.org/wiki/Boids)
was used only for discovery; its task page and examples were not consulted.

This does not duplicate [`particle_swarm_optimization`](../particle_swarm_optimization/README.md),
which searches an objective using personal/global bests, or
[`benchmarkgame_nbody`](../benchmarkgame_nbody/README.md), which updates
gravitational forces among five fixed bodies.

## Workload and ports

`workload.json` pins behavior, error/capacity cases, bounds, and expected
output bytes. [`INVENTORY.json`](INVENTORY.json) pins the ten source paths and
fixture identifiers; `check_inventory.py` reviews those paths and byte bounds,
and `verify_workload.py` compares every golden fixture against both references.
Build with the shared ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm boids_flocking_simulation --language rust
```

| Language | Source |
|---|---|
| C | [`c/b/boids_flocking_simulation.c`](../../../c/b/boids_flocking_simulation.c) |
| C3 | [`c3/b/boids_flocking_simulation.c3`](../../../c3/b/boids_flocking_simulation.c3) |
| C++ | [`cpp/b/boids_flocking_simulation.cpp`](../../../cpp/b/boids_flocking_simulation.cpp) |
| Elisa | [`elisa/b/boids_flocking_simulation.elisa`](../../../elisa/b/boids_flocking_simulation.elisa) |
| Mojo | [`mojo/b/boids_flocking_simulation.mojo`](../../../mojo/b/boids_flocking_simulation.mojo) |
| Nim | [`nim/b/boids_flocking_simulation.nim`](../../../nim/b/boids_flocking_simulation.nim) |
| Odin | [`odin/b/boids_flocking_simulation.odin`](../../../odin/b/boids_flocking_simulation.odin) |
| Rust | [`rust/b/boids_flocking_simulation.rs`](../../../rust/b/boids_flocking_simulation.rs) |
| V | [`v/b/boids_flocking_simulation.v`](../../../v/b/boids_flocking_simulation.v) |
| Zig | [`zig/b/boids_flocking_simulation.zig`](../../../zig/b/boids_flocking_simulation.zig) |

No Rosetta Code task prose, example values, submissions, or source code are
used. No program or validation tool has been run.

# Two-dimensional elastic collision

This benchmark follows the pinned Java `ElasticCollision2D.resolveCollision` operation for two circular bodies with coefficient of restitution 1. It computes the center-to-center normal, returns the first body's velocity unchanged when the bodies overlap or move apart, and otherwise applies the impulse along that normal. The contract excludes coincident centers, which would make the source's normal undefined.

Input is `[ax, ay, avx, avy, mass_a, radius_a, bx, by, bvx, bvy, mass_b, radius_b]`, with each value in thousandths. Positions are in [-200000, 200000], velocities in [-5000, 5000], masses in [1000, 100000], and radii in [1, 10000]. The result packs the first body's post-collision velocity components rounded with `floor(value + 0.5)` to signed 16-bit thousandths, x in the high half and y in the low half. Malformed inputs and results outside that representation return -1. Runtime oracle: `elastic_collision2_d_oracle.py`.

Pinned source: [Java `ElasticCollision2D.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/physics/ElasticCollision2D.java).

## Language ports

| Language | Source |
| --- | --- |
| C | [c/e/elastic_collision2_d.c](../../../c/e/elastic_collision2_d.c) |
| C3 | [c3/e/elastic_collision2_d.c3](../../../c3/e/elastic_collision2_d.c3) |
| C++ | [cpp/e/elastic_collision2_d.cpp](../../../cpp/e/elastic_collision2_d.cpp) |
| Elisa | [elisa/e/elastic_collision2_d.elisa](../../../elisa/e/elastic_collision2_d.elisa) |
| Nim | [nim/e/elastic_collision2_d.nim](../../../nim/e/elastic_collision2_d.nim) |
| Odin | [odin/e/elastic_collision2_d.odin](../../../odin/e/elastic_collision2_d.odin) |
| Rust | [rust/e/elastic_collision2_d.rs](../../../rust/e/elastic_collision2_d.rs) |
| V | [v/e/elastic_collision2_d.v](../../../v/e/elastic_collision2_d.v) |
| Zig | [zig/e/elastic_collision2_d.zig](../../../zig/e/elastic_collision2_d.zig) |

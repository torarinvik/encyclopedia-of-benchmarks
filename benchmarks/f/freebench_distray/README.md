# FreeBench Distray

This package implements a bounded one-pixel profile of the pinned FreeBench Distray benchmark. It retains the source scene, camera projection, stochastic ray distribution, sphere and ground-plane intersections, shadow tests, diffuse shading, and recursive reflections. It omits the full 640×480 raster loop, PPM framing, timing, and diagnostic output.

## Contract

The i64_array_bytes_output ABI accepts [distribution, pixel_x, pixel_y]. distribution is 1–5, matching the pinned launcher inputs; pixel coordinates are 0 <= x < 640 and 0 <= y < 480. Each call resets the source LCG seed to 0x52462467, then computes the selected pixel using the original 640×480 camera scale and source ray rules. This makes calls reproducible while keeping the selected pixel's full applicable ray path.

The three output bytes are the source pixel's red, green, and blue channels. Each is converted from its averaged channel value by truncation after multiplication by 255, then has its low bit cleared, matching the pinned PPM writer's memory[i] & ~1 operation. Success returns 3. Invalid framing, distribution, or coordinates returns -1. Null or short output returns -2 without writing.

The workload includes hand-derived top-left sky cases for launcher distributions 1 and 5. The independent oracle computes the result for every bounded pixel and distribution, including the sphere-hit, shadow, and reflection paths. The top-left fixtures are useful for the framing and deterministic sampling contract; generated verifier cases should include interior pixels such as (320, 240) to cover the scene-intersection path.

## Provenance and rights

- Pinned source: [FreeBench/distray/distray.c](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/distray/distray.c), commit 5d7b75df749241efa7a6e6f5be613d3fcc5cce38.
- Pinned launcher: [FreeBench/distray/info.sh](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/distray/info.sh). It selects test.in or ref.in, whose single values are 1 and 5 for DISTRIB.
- The source credits Marcus Geelnard as ray-tracer author and Peter Rundberg (biff@ce.chalmers.se) for benchmarkification.
- No license statement or license file is present in the pinned source, its directory, or the repository root. No upstream license grant is inferred. The ports are independent implementations and retain the source attribution; this package does not grant rights to the upstream work.

## Ports

| Language | File |
|---|---|
| C | [c/f/freebench_distray.c](../../../c/f/freebench_distray.c) |
| C3 | [c3/f/freebench_distray.c3](../../../c3/f/freebench_distray.c3) |
| C++ | [cpp/f/freebench_distray.cpp](../../../cpp/f/freebench_distray.cpp) |
| Elisa | [elisa/f/freebench_distray.elisa](../../../elisa/f/freebench_distray.elisa) |
| Nim | [nim/f/freebench_distray.nim](../../../nim/f/freebench_distray.nim) |
| Odin | [odin/f/freebench_distray.odin](../../../odin/f/freebench_distray.odin) |
| Rust | [rust/f/freebench_distray.rs](../../../rust/f/freebench_distray.rs) |
| V | [v/f/freebench_distray.v](../../../v/f/freebench_distray.v) |
| Zig | [zig/f/freebench_distray.zig](../../../zig/f/freebench_distray.zig) |

- Oracle: [freebench_distray_oracle.py](../../freebench_distray_oracle.py)
- Contract and fixtures: [workload.json](workload.json)

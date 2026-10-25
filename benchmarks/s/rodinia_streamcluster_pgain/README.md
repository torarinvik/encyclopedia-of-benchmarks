# Rodinia streamcluster `pgain` profile

This package isolates the facility-opening local-search operation `pgain` from the pinned Rodinia streamcluster source. It evaluates one candidate point against a supplied feasible assignment, accumulates direct reassignment changes and per-center closure costs, and commits the opening only when the total opening cost is strictly negative. This is facility-location/k-median local search, distinct from the repository's Lloyd k-means packages.

## Contract

- ABI: `i64_array_bytes_output`; exported symbol: `rodinia_streamcluster_pgain`.
- Input words are `[n, dimension, candidate, facility_cost, center_mask, assignments[n], weights[n], current_costs[n], coordinates[n*dimension]]`; coordinates are point-major. The candidate must not already be an open center.
- Bounds: `2 <= n <= 8`, `1 <= dimension <= 3`, facility cost `1..64`, point weights `1..4`, integer coordinates `-8..8`, and a nonempty center mask. Input length is exactly `5 + n*(3+dimension)` (maximum 53 words).
- The input assignment is validated as a feasible current state: every assignment names an open center; each open center assigns to itself at zero cost; each supplied cost equals `weight * squared_euclidean_distance` to its assigned center. All intermediate distances and costs remain exact integers, matching the source's squared-distance arithmetic on this bounded profile.
- Process points and centers in ascending index order. For each point, compare weighted squared distance to the candidate with its current cost. Strictly cheaper candidates switch directly and add their cost difference to the opening delta. Otherwise the difference contributes to the assigned center's `lower` accumulator. For each open center, compute `facility_cost + lower`; a strictly positive value marks it for closure and is subtracted from the opening delta. Commit iff the final delta is `< 0`.
- On commit, directly switched points and all points assigned to closing centers move to the candidate; centers with positive closure values are removed and the candidate is opened. Ties do not switch or close. The result is little-endian signed 64-bit words `[opened, gain, center_count, center_mask, objective, assignments'[n], costs'[n]]`, where gain is zero on rejection and otherwise the negated opening delta, and objective is `center_count*facility_cost + sum(costs')`.
- Malformed input returns `-1`. For valid input, null output or insufficient byte capacity returns `-2` without writing. Success returns the number of output words (`5+2*n`) and writes exactly `8*(5+2*n)` bytes.

This is the source's `pgain` core, not the randomized `pspeedy` initializer, repeated local-search schedule, command-line parser, or launcher timing profile. The pinned launcher is `cuda/streamcluster/run` and runs `./sc_gpu 10 20 256 65536 65536 1000 none output.txt`; the package bounds a single operation within that much larger execution.

## Provenance and rights

Pinned repository: [`utcs-scea/rodinia`](https://github.com/utcs-scea/rodinia/tree/f30e63663cfb114939a15c7ffc4ae112055ae6a8), commit `f30e63663cfb114939a15c7ffc4ae112055ae6a8`. The algorithm is taken from [`cuda/streamcluster/streamcluster_original.cpp`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/streamcluster/streamcluster_original.cpp), especially `dist` and `pgain`; the pinned launcher is [`cuda/streamcluster/run`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/streamcluster/run). Ports are independently written implementations of the bounded contract. The source's Princeton notice and the repository's University of Virginia notice/citation request are retained in [`LICENSE.txt`](LICENSE.txt).

The independent model is [`benchmarks/rodinia_streamcluster_pgain_oracle.py`](../../rodinia_streamcluster_pgain_oracle.py). Static workload fixtures are in [`workload.json`](workload.json). Ports are in `c/s`, `c3/s`, `cpp/s`, `elisa/s`, `nim/s`, `odin/s`, `rust/s`, `v/s`, and `zig/s`.

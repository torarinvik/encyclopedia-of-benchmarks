# Package inventory

Algorithm: `cohen_sutherland`  
ABI: `i64_array_float64`  
Input: 9 signed 64-bit values in `[component,xmin,ymin,xmax,ymax,x1,y1,x2,y2]` order. Coordinates are integer millionths in `[-1,000,000,000,1,000,000,000]`; selectors are `0..4`; rectangle width and height are positive.  
Maximum valid / parseable input lengths: 9 / 10 words.  
Result: one scalar binary64 coordinate, `1.0`/`0.0` acceptance flag, or `-1e300` invalid/rejected-coordinate sentinel.  
Workspace: 0 bytes of variable scratch; scalar locals are constant state.  
Comparison tolerance: absolute `1e-9`, relative `1e-12`.

## Native ports

- `c/c/cohen_sutherland.c`
- `c3/c/cohen_sutherland.c3`
- `cpp/c/cohen_sutherland.cpp`
- `elisa/c/cohen_sutherland.elisa`
- `mojo/c/cohen_sutherland.mojo`
- `nim/c/cohen_sutherland.nim`
- `odin/c/cohen_sutherland.odin`
- `rust/c/cohen_sutherland.rs`
- `v/c/cohen_sutherland.v`
- `zig/c/cohen_sutherland.zig`

## References and metadata

- Primary: `benchmarks/cohen_sutherland_oracle.py` (outcode iteration)
- Independent: `benchmarks/c/cohen_sutherland/independent_oracle.py` (parametric interval)
- Workload: `benchmarks/c/cohen_sutherland/workload.json`
- Workload agreement helper: `benchmarks/c/cohen_sutherland/verify_workload.py`
- Static package inventory: `benchmarks/c/cohen_sutherland/check_inventory.py`
- Rights and provenance: `benchmarks/c/cohen_sutherland/RIGHTS.md`
- Shared ABI integration: `benchmarks/run_i64_array_float64.py` and `benchmarks/verify_i64_array_float64.py`

Primary algorithm source: [McGill computer graphics clipping notes](https://cim.mcgill.ca/~langer/557/6-slides-9pp.pdf). Source behavior cross-check: [pinned TheAlgorithms/Java implementation](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/lineclipping/CohenSutherland.java). Algorithm ideas only; see `RIGHTS.md`.

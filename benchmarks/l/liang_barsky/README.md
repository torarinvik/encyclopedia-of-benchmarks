# Liang–Barsky line clipping

The pinned Java implementation clips a parametric segment against left, right, bottom, and top rectangle boundaries in that order, updating `t0` and `t1` and then calculating the endpoints. The benchmark bounds integer coordinates and quantizes the clipped endpoints to thousandths for the scalar ABI.

## Contract

Input is `[xmin,ymin,xmax,ymax,x0,y0,x1,y1]`, with all coordinates in [-5,5], `xmin < xmax`, and `ymin < ymax`. Nonintersecting segments return -1. Intersecting endpoint coordinates are rounded to thousandths (nearest, ties away from zero) and packed in `(x0,y0,x1,y1)` order as base-10001 digits after adding 5000.

See [workload](workload.json), [oracle](../../liang_barsky_oracle.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/lineclipping/LiangBarsky.java).

| Language | Port |
|---|---|
| C | c/l/liang_barsky.c |
| C3 | c3/l/liang_barsky.c3 |
| C++ | cpp/l/liang_barsky.cpp |
| Elisa | elisa/l/liang_barsky.elisa |
| Nim | nim/l/liang_barsky.nim |
| Odin | odin/l/liang_barsky.odin |
| Rust | rust/l/liang_barsky.rs |
| V | v/l/liang_barsky.v |
| Zig | zig/l/liang_barsky.zig |

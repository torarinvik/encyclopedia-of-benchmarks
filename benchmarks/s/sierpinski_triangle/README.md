# Sierpinski triangle

This package ports the pinned Python source's recursive turtle drawing as a deterministic virtual-turtle trace. Each recursive call emits its triangle outline in source order, then visits the three midpoint subtriangles in source order. Repeated parent and child edges are preserved because the source draws each outline independently.

## Contract

The `i64_array_bytes_output` ABI accepts exactly `[depth]`, where depth is 0 through 4. The source CLI vertices are fixed at `(-175,-125)`, `(0,175)`, and `(175,-125)`. Each call emits directed segments `v1→v2`, `v2→v3`, `v3→v1`, then recurses into `(v1, midpoint(v1,v2), midpoint(v1,v3))`, `(v2, midpoint(v1,v2), midpoint(v2,v3))`, and `(v3, midpoint(v3,v2), midpoint(v1,v3))`.

Each segment is four signed i64 little-endian coordinates `[x0,y0,x1,y1]`, with every source coordinate multiplied by 16. This fixed-point scale exactly represents all source midpoints through depth 4. Output has no header. Depth `d` has `(3^(d+1)-1)/2` triangle calls and three segments per call; output sizes range from 96 bytes at depth 0 to 11,616 bytes at depth 4. Invalid input returns `-1`. For valid input, a null output pointer or insufficient capacity returns `-2` without writing. Success returns bytes written.

The benchmark records turtle drawing commands without opening a GUI. It is distinct from the Sierpinski carpet raster benchmark. The pinned source is TheAlgorithms/Python, commit `e1a2a8b016001309a73d5fec4818c35cca139795`, path `fractals/sierpinski_triangle.py`; see the [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/fractals/sierpinski_triangle.py), [workload](workload.json), and [oracle](../../sierpinski_triangle_oracle.py).

| Language | Port |
|---|---|
| C | ../../../c/s/sierpinski_triangle.c |
| C3 | ../../../c3/s/sierpinski_triangle.c3 |
| C++ | ../../../cpp/s/sierpinski_triangle.cpp |
| Elisa | ../../../elisa/s/sierpinski_triangle.elisa |
| Nim | ../../../nim/s/sierpinski_triangle.nim |
| Odin | ../../../odin/s/sierpinski_triangle.odin |
| Rust | ../../../rust/s/sierpinski_triangle.rs |
| V | ../../../v/s/sierpinski_triangle.v |
| Zig | ../../../zig/s/sierpinski_triangle.zig |

Build and record with the shared ABI after serialized integration is complete:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm sierpinski_triangle --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm sierpinski_triangle
```

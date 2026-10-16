# first_fundamental_form

The pinned Python implementation parses symbolic coordinates `r(u,v)`, differentiates them, and returns the first fundamental form coefficients `E = r_u · r_u`, `F = r_u · r_v`, and `G = r_v · r_v`, simplified as SymPy expressions.

This bounded benchmark represents each of `x`, `y`, and `z` by six integer coefficients in the basis `[1, u, v, u², uv, v²]`, with each coefficient in `[-100, 100]`. The nine ports differentiate those polynomials and compute the exact coefficient vectors of E, F, and G. The scalar result is the signed interpretation of FNV-1a over those 18 output coefficients, ordered E, F, G and using the same six-term basis for each. Invalid lengths or coefficients return `-1`.

The contract captures exact polynomial differentiation and dot products for total degree at most two; it does not include general SymPy parsing or symbolic simplification of expressions outside this basis. The pinned source uses SymPy to parse each coordinate expression, differentiate `r(u,v)` by `u` and `v`, and simplify the three dot products. There is no equivalent existing benchmark for a surface's first fundamental form; area and surface-area packages compute scalar geometric measures instead.

See the [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/first_fundamental_form.py) and [`workload.json`](workload.json). Verify all nine ports with `python3 benchmarks/verify_i64_array_scalar.py --algorithms first_fundamental_form`.

| Language | Port |
|---|---|
| C | [`c/f/first_fundamental_form.c`](../../../c/f/first_fundamental_form.c) |
| C3 | [`c3/f/first_fundamental_form.c3`](../../../c3/f/first_fundamental_form.c3) |
| C++ | [`cpp/f/first_fundamental_form.cpp`](../../../cpp/f/first_fundamental_form.cpp) |
| Elisa | [`elisa/f/first_fundamental_form.elisa`](../../../elisa/f/first_fundamental_form.elisa) |
| Nim | [`nim/f/first_fundamental_form.nim`](../../../nim/f/first_fundamental_form.nim) |
| Odin | [`odin/f/first_fundamental_form.odin`](../../../odin/f/first_fundamental_form.odin) |
| Rust | [`rust/f/first_fundamental_form.rs`](../../../rust/f/first_fundamental_form.rs) |
| V | [`v/f/first_fundamental_form.v`](../../../v/f/first_fundamental_form.v) |
| Zig | [`zig/f/first_fundamental_form.zig`](../../../zig/f/first_fundamental_form.zig) |

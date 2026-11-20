# Fundamental Pell solution

For a nonsquare `D` in `2..31`, find the least positive integer pair `(x,y)`
satisfying `x^2 - D*y^2 = 1`. Input is `[D]`; out-of-domain and square `D`
values return `-1`.

The primary expands `sqrt(D)` as a continued fraction and examines convergents
until one satisfies the Pell identity. It returns `(x << 32) | y`; callers
recover `x` from the high 32 bits and `y` from the low 32 bits. In this bounded
domain both fit in 32 bits. The primary runs in time proportional to the
continued-fraction period explored and uses `O(1)` auxiliary space. An
independent bounded search scans `y` and checks whether `D*y*y+1` is a square.

This solves a Diophantine equation for the least fundamental solution. It is
distinct from the local `pell_number` recurrence, which produces terms of a
sequence, and from the generic continued-fraction converter, which evaluates
finite rational expansions.

The mathematical method is described in [OI Wiki's Pell equation
reference](https://oi-wiki.org/math/number-theory/pell-equation/). The package
uses the reference for the algorithm idea only; see [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [c/p/pell_fundamental_solution.c](../../../c/pell_fundamental_solution.c) |
| C3 | [c3/p/pell_fundamental_solution.c3](../../../c3/pell_fundamental_solution.c3) |
| C++ | [cpp/p/pell_fundamental_solution.cpp](../../../cpp/pell_fundamental_solution.cpp) |
| Elisa | [elisa/p/pell_fundamental_solution.elisa](../../../elisa/pell_fundamental_solution.elisa) |
| Mojo | [mojo/p/pell_fundamental_solution.mojo](../../../mojo/pell_fundamental_solution.mojo) |
| Nim | [nim/p/pell_fundamental_solution.nim](../../../nim/pell_fundamental_solution.nim) |
| Odin | [odin/p/pell_fundamental_solution.odin](../../../odin/pell_fundamental_solution.odin) |
| Rust | [rust/p/pell_fundamental_solution.rs](../../../rust/pell_fundamental_solution.rs) |
| V | [v/p/pell_fundamental_solution.v](../../../v/pell_fundamental_solution.v) |
| Zig | [zig/p/pell_fundamental_solution.zig](../../../zig/pell_fundamental_solution.zig) |

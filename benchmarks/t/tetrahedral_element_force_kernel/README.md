# Tetrahedral element force kernel

For each independent linear tetrahedral element, compute the four nodal
internal-force contributions for isotropic small-strain elasticity. The
reference tetrahedron has vertices `(0,0,0)`, `(1,0,0)`, `(0,1,0)`, and
`(0,0,1)`. Each record supplies the four deformed positions in that vertex
order. The two integer Lamé parameters are shared by all records.

The input is `[M,lambda,mu, xyz[0..12*M-1]]`, where `1 <= M <= 32`,
`0 <= lambda,mu <= 16`, and each coordinate is an integer in `[-4,4]`. The
exact length is `3+12*M`, with a maximum valid length of 387 words and a
maximum parseable length of 388 words. For each tetrahedron, form the
deformation gradient `F` from the three deformed edge columns, then the
infinitesimal strain `E=(F+F^T)/2-I` and stress
`sigma=lambda*tr(E)*I+2*mu*E`. The reference volume is `1/6`; the four forces
are `-V*sigma*grad(N_i)`. Return each force component multiplied by six, in
element, vertex, and x/y/z order. This scaling makes every output an exact
signed integer for the bounded input.

The ABI is `int64_t tetrahedral_element_force_kernel(const int64_t *input,
size_t length, uint8_t *output, size_t capacity)`. Malformed or null input
returns `-1`. A null output or capacity below `96*M` returns `-2`; complete
input validation takes precedence, and errors write no output. Success returns
the number of little-endian output bytes, at most 3072. The element-local
kernel takes `O(M)` time and constant scratch space.

This profile measures element force evaluation independently for each
tetrahedron; it does not include mesh connectivity or global scatter
assembly. The [PARSEC technical report](https://www.cs.princeton.edu/techreports/2010/890.pdf)
describes Facesim's Add Forces kernel as evaluating each tetrahedron and
contributing forces to its four nodes. The [FEniCSx linear-elasticity
tutorial](https://jsdokken.com/dolfinx-tutorial/main/chapter2/linearelasticity.html)
defines the small-strain stress relation, and the [Physics-Based Simulation
book](https://phys-sim-book.github.io/finite-element-method/3d-elastodynamics/elasticity.html)
describes the constant deformation gradient and shape-function gradients for
a linear tetrahedron. These references identify the methods; the bounded
contract, records, and implementations are written independently. See
[`RIGHTS.md`](RIGHTS.md).

The primary reference uses the direct element stress and shape-gradient
formula. The independent reference differentiates the quadratic strain energy
with exact central differences, which recover its gradient exactly. The
workload includes rest state, rigid translation, uniform dilation, shear,
malformed frames, null pointers, and insufficient capacities. No port has
been compiled or executed.

| Language | Source |
|---|---|
| C | [c/t/tetrahedral_element_force_kernel.c](../../../c/t/tetrahedral_element_force_kernel.c) |
| C3 | [c3/t/tetrahedral_element_force_kernel.c3](../../../c3/t/tetrahedral_element_force_kernel.c3) |
| C++ | [cpp/t/tetrahedral_element_force_kernel.cpp](../../../cpp/t/tetrahedral_element_force_kernel.cpp) |
| Elisa | [elisa/t/tetrahedral_element_force_kernel.elisa](../../../elisa/t/tetrahedral_element_force_kernel.elisa) |
| Mojo | [mojo/t/tetrahedral_element_force_kernel.mojo](../../../mojo/t/tetrahedral_element_force_kernel.mojo) |
| Nim | [nim/t/tetrahedral_element_force_kernel.nim](../../../nim/t/tetrahedral_element_force_kernel.nim) |
| Odin | [odin/t/tetrahedral_element_force_kernel.odin](../../../odin/t/tetrahedral_element_force_kernel.odin) |
| Rust | [rust/t/tetrahedral_element_force_kernel.rs](../../../rust/t/tetrahedral_element_force_kernel.rs) |
| V | [v/t/tetrahedral_element_force_kernel.v](../../../v/t/tetrahedral_element_force_kernel.v) |
| Zig | [zig/t/tetrahedral_element_force_kernel.zig](../../../zig/t/tetrahedral_element_force_kernel.zig) |

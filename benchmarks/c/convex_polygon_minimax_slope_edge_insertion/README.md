# Convex-polygon minimax slope edge insertion

This package benchmarks a bounded clean-room profile of lifted min-max-slope triangulation. Each input vertex `(x,y,z)` lifts a strictly convex planar boundary point to height `z`. A triangle defines a plane `z=f(x,y)` and has slope `sqrt((df/dx)^2 + (df/dy)^2)`. The objective minimizes the largest triangle slope in a triangulation.

The profile uses the edge-insertion idea described in Tiow-Seng Tan's [“Optimal Triangulation” chapter](https://doi.org/10.1007/978-1-4939-2864-4_715) and Bern, Edelsbrunner, Eppstein, Mitchell, and Tan's [edge-insertion paper](https://doi.org/10.1007/BF02573962) ([author-hosted copy](https://www.comp.nus.edu.sg/~tants/Paper/eis.pdf)). It begins with the 0-2 fan of a quadrilateral, examines maximum-slope triangles and their anchor vertices in deterministic order, and inserts the candidate diagonal only when it properly crosses the opposite edge and strictly reduces the maximum slope. The closed tangent wedge defines the descent-ray anchor test; a boundary ray qualifies. The code compares squared slopes as exact rational values using integer cross products, with no floating-point arithmetic.

Input is `[N,x0,y0,z0,...]`, with `N=3` or `4` and coordinates in `[-8,8]`. The projected points must be strictly convex in the supplied cyclic order, with no three collinear. A four-vertex lifted input must have nonzero volume; coplanar lifted quadrilaterals are rejected rather than handled by simulated perturbation. These conditions make the bounded workload deterministic and match the paper's general-position premise.

The scalar output is the one-based rank of the optimal maximum slope among distinct slopes from every three-vertex subset. Equal rational slopes share a rank. Invalid, null, malformed, or out-of-profile input returns `-1`. The independent oracle enumerates the one triangle or both quadrilateral triangulations and directly minimizes their maximum slope.

This small profile demonstrates the paper's local edge-insertion step; it does not claim to reproduce the paper's general-point-set algorithm or its asymptotic bounds. It is distinct from min-max-angle triangulation, which optimizes angles, and max-min-height triangulation, which optimizes triangle altitude.

## Language ports

- [C](../../../c/c/convex_polygon_minimax_slope_edge_insertion.c)
- [C3](../../../c3/c/convex_polygon_minimax_slope_edge_insertion.c3)
- [C++](../../../cpp/c/convex_polygon_minimax_slope_edge_insertion.cpp)
- [Elisa](../../../elisa/c/convex_polygon_minimax_slope_edge_insertion.elisa)
- [Mojo](../../../mojo/c/convex_polygon_minimax_slope_edge_insertion.mojo)
- [Nim](../../../nim/c/convex_polygon_minimax_slope_edge_insertion.nim)
- [Odin](../../../odin/c/convex_polygon_minimax_slope_edge_insertion.odin)
- [Rust](../../../rust/c/convex_polygon_minimax_slope_edge_insertion.rs)
- [V](../../../v/c/convex_polygon_minimax_slope_edge_insertion.v)
- [Zig](../../../zig/c/convex_polygon_minimax_slope_edge_insertion.zig)

The workload records the complete ABI and fixture contract. `convex_polygon_minimax_slope_edge_insertion_oracle.py` is the primary reference; `convex_polygon_minimax_slope_edge_insertion_verifier_oracle.py` independently enumerates candidate triangulations. `check_convex_polygon_minimax_slope_edge_insertion_package.py` provides static inventory and fixture review.

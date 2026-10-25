# DOE miniAMR 7-Point and 27-Point Stencil Averages

This package ports both branches of `stencil_calc` from the pinned
[`DOE_ProxyApps_C/miniAMR/stencil.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/DOE_ProxyApps_C/miniAMR/stencil.c)
at `lac-dcc/Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`.

The input describes one block and includes its one-cell halo. `stencil` is
either `7`, selecting the source's center-plus-six-axis-neighbor average, or
`27`, selecting its full 3×3×3 box average. The source computes all interior
cells into a work buffer before copying them back; the ports retain that
two-phase behavior. Cell addition order follows the pinned source. The array
layout is `array[i][j][k]`, with `k` varying fastest, and traversal is `i`,
then `j`, then `k`.

The `i64_array_float64` ABI exports
`doe_miniamr_stencil_average(values, length)`. Input is
`[stencil, nx, ny, nz, haloed_grid...]`. Each interior dimension is 2 or 4;
the haloed grid has dimensions `(nx+2) × (ny+2) × (nz+2)` and exactly
`4+(nx+2)*(ny+2)*(nz+2)` entries. Grid values are signed integers in
`[-1000, 1000]`. The output is a scalar projection of the staged interior:
`sum((q+1)*work[q]^2)`, where `q` starts at zero in source traversal order.
This projection exposes every updated cell through its value and position.
Invalid input returns `-1e300`; output comparisons use relative and absolute
tolerances of `1e-12`.

This is a three-dimensional block stencil with a one-cell halo. It is distinct
from local 2D convolution packages and from iterative PDE solvers such as
PolyBench heat-3d, whose center-difference weighting and repeated two-grid
updates are different operations. The package does not port miniAMR's MPI
communication, block refinement, load balancing, or full application driver.

[`workload.json`](workload.json) covers the zero field, a constant field, and
a hand-derived isolated interior impulse in both stencil modes, plus malformed
length and null-input cases. The independent oracle is
[`benchmarks/doe_miniamr_stencil_average_oracle.py`](../../doe_miniamr_stencil_average_oracle.py).

The source header is Copyright (2014) Sandia Corporation under Contract
DE-AC04-94AL85000 and states the GNU LGPL version 2.1 or (at the recipient's
option) any later version; it also notes retained U.S. Government rights and
names Courtenay T. Vaughan and Richard F. Barrett as contacts. The pinned
miniAMR subtree supplies the full GNU LGPL version 3 text, copied to
[`LICENSE.txt`](LICENSE.txt). Each port retains the complete source header.

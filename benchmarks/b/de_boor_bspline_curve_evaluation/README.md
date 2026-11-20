# de Boor B-spline curve evaluation

This package evaluates one scalar B-spline curve value from a bounded knot vector and control-point list. It uses the de Boor local control-polygon recurrence. The repository's Catmull–Clark package performs mesh subdivision, while this package evaluates a supplied univariate spline at one parameter; Bézier-specific evaluation is also a separate curve family and contract.

## Contract

The `float64_slice_io` input is:

```text
[degree, control_count, parameter, knots..., controls...]
```

All entries must be finite binary64 values. `degree` is an exact integer in `[1,3]`; `control_count` is an exact integer in `[degree+1,8]`. The knot count is `control_count + degree + 1`, and the control list has `control_count` values. Knots must be nondecreasing, each equal-knot run may have multiplicity at most `degree+1`, all knots and controls lie in `[-1000,1000]`, and the active domain `[knots[degree], knots[control_count]]` must have positive length. The parameter must lie in that closed active domain.

For an interior parameter, the selected span is the rightmost index `k` with `U[k] <= parameter < U[k+1]`. At the active upper endpoint `parameter == U[control_count]`, the span is `control_count-1`. These rules make evaluation deterministic at repeated knots and at the right endpoint. In a zero-denominator recurrence step, the interpolation weight is defined as zero.

The primary initializes `degree+1` neighboring controls and performs the triangular de Boor blends. The independent reference builds the local Cox–de Boor basis weights and takes their weighted control-point sum. They share the input parser, but the independent reference has its own explicit span selection and a different value recurrence. Degree at most three bounds the primary's local array to four doubles. The independent reference's basis and left/right arrays use at most 96 bytes, with at most four transient float64 values; the package scratch cap is 128 bytes. The native primary ports use only a four-double local array. Since all recurrence weights lie in `[0,1]`, finite bounded controls keep every blend finite and within the control range.

Success writes one float64 and returns `1`. Malformed or null input returns `-1`; valid input with null output or capacity below one returns `-2` without writes. Input validation takes precedence over output validation. The valid frame length ranges from 9 to 23 values; the parser accepts at most 24 values so one trailing-value error case is representable. The workload uses absolute and relative tolerances of `1e-12`.

## References and provenance

The primary recurrence follows the geometric de Boor curve-evaluation procedure in [Algorithm 1.5 of *Splines in Industrial Applications*](https://www.fim.uni-passau.de/fileadmin/dokumente/fakultaeten/fim/lehrstuhl/sauer/geyer/SplinesinIndustry.pdf). The independent reference uses the [Cox–de Boor recursive basis definition in MIT's computational geometry notes, §6.2.2](https://ocw.mit.edu/courses/2-158j-computational-geometry-spring-2003/e58d71723e462b96821a8351d8e729ba_lecnotes6.pdf). The task title is recorded in the pinned [RosettaCodeData popular-task index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks) as discovery context only. The package contains no copied implementation, task text, example, or test from these sources. The degree and length bounds, scalar ABI, fixtures, references, and native ports are clean-room benchmark choices. See [RIGHTS.md](RIGHTS.md).

## Package files

- Primary reference: [primary_oracle.py](primary_oracle.py)
- Independent reference: [independent_oracle.py](independent_oracle.py)
- Workload and ABI fixtures: [workload.json](workload.json)
- Static workload helper: [verify_workload.py](verify_workload.py)
- Static inventory helper: [check_inventory.py](check_inventory.py)
- Full source paths: [INVENTORY.json](INVENTORY.json)

## Native ports

| Language | Source |
|---|---|
| C | [`c/b/de_boor_bspline_curve_evaluation.c`](../../../c/b/de_boor_bspline_curve_evaluation.c) |
| C3 | [`c3/b/de_boor_bspline_curve_evaluation.c3`](../../../c3/b/de_boor_bspline_curve_evaluation.c3) |
| C++ | [`cpp/b/de_boor_bspline_curve_evaluation.cpp`](../../../cpp/b/de_boor_bspline_curve_evaluation.cpp) |
| Elisa | [`elisa/b/de_boor_bspline_curve_evaluation.elisa`](../../../elisa/b/de_boor_bspline_curve_evaluation.elisa) |
| Mojo | [`mojo/b/de_boor_bspline_curve_evaluation.mojo`](../../../mojo/b/de_boor_bspline_curve_evaluation.mojo) |
| Nim | [`nim/b/de_boor_bspline_curve_evaluation.nim`](../../../nim/b/de_boor_bspline_curve_evaluation.nim) |
| Odin | [`odin/b/de_boor_bspline_curve_evaluation.odin`](../../../odin/b/de_boor_bspline_curve_evaluation.odin) |
| Rust | [`rust/b/de_boor_bspline_curve_evaluation.rs`](../../../rust/b/de_boor_bspline_curve_evaluation.rs) |
| V | [`v/b/de_boor_bspline_curve_evaluation.v`](../../../v/b/de_boor_bspline_curve_evaluation.v) |
| Zig | [`zig/b/de_boor_bspline_curve_evaluation.zig`](../../../zig/b/de_boor_bspline_curve_evaluation.zig) |

The Elisa entrypoint uses borrowed ABI references and bounded views for internal access. This package has not been compiled or executed.

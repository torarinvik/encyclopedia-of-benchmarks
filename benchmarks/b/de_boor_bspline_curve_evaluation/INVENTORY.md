# Package inventory

- Package: `de_boor_bspline_curve_evaluation`
- ABI: `float64_slice_io`
- Input: `[degree, control_count, parameter, knots..., controls...]`
- Valid / parseable frame lengths: 9–23 / 24 float64 values
- Output: one evaluated scalar curve value; invalid input `-1`; output error `-2`
- Output workspace: 1 float64 element; internal scratch cap: 128 bytes, including independent local basis temporaries
- References: `primary_oracle.py`, `independent_oracle.py`
- Workload: `workload.json`
- Static helpers: `verify_workload.py`, `check_inventory.py`
- Provenance: Algorithm 1.5 in *Splines in Industrial Applications*; MIT's Cox–de Boor basis notes; RosettaCodeData pinned title index for discovery only

The ten native source paths are listed in `INVENTORY.json`. Elisa keeps its internal algorithm in bounded views and uses borrowed references only at the exported ABI boundary. The package is registered in the shared float64-slice runner and verifier, README, catalog, and expansion ledger. No program, helper, checker, test, build, or compiler has been run.

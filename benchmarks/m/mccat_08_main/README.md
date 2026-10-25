# McCat 08-main hierarchical 3D transforms

This package extracts the portable object-transform loop from McCat 08-main. The source creates a parent object and a sphere child, transforms the child's unique points for each parent rotation, and prints the final object state. The bounded profile supplies a point list directly and returns a checksum over each frame, so the repeated transformations remain observable. Sphere tessellation, debug printing, and the unused renderer call are outside the core.

## Contract

The `i64_array_scalar` entry point is `mccat_08_main`. Input layout is `[frame_count, raw_point_count, child_scale_xyz, child_rotation_xyz_degrees, child_translation_xyz, parent_scale_xyz, parent_rotation_xyz_degrees, parent_translation_xyz, point_xyz...]`. All transform and coordinate values are signed integers scaled by 1,000,000. There are 1–16 raw points and 1–360 frames. Scales are bounded to `[-4,4]`, angles to `[-360,360]` degrees, and coordinates/translations to `[-100,100]` units.

Points whose coordinates are identical at micro-unit resolution are deduplicated in input order, matching the source's `InsertPoint` tolerance of less than 1e-6. For each frame the port applies, in source order, the child scale, child Euler rotation, child translation, parent scale, parent Euler rotation, and parent translation. Euler rotation is the source's `Rx * Ry * Rz` matrix product. The parent y angle is increased by the zero-based frame index, matching the launcher's `Rotation.y = i` sweep.

The result sums, for each unique point and every frame, the nearest-milli projection of the transformed coordinates using `frame_index+1` and `point_index+1` weights: `weight * (x_milli + 3*y_milli + 7*z_milli)`. Rounding ties are away from zero. Invalid framing or values return `-1`.

This is related to the local single-axis `vector3_axis_rotation` operation, but the package preserves the source's two-level scale/rotation/translation sequence, Euler matrix order, point deduplication, and repeated scene update loop.

## Pinned source and notice

Source: [`McCat/08-main`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/08-main) in `lac-dcc/Benchmarks`, commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher compiles `convert.c`, `main.c`, `object.c`, and `trig.c` with `-lm`. The source credits Peter Riishoej Brinkler and carries this permission notice:

```text
Copyright (C) 1996 McGill University.
Copyright (C) 1996 McCAT System Group.
Copyright (C) 1996 ACAPS Benchmark Administrator
                   benadmin@acaps.cs.mcgill.ca

This program is free software; you can redistribute it and/or modify
it provided this copyright notice is maintained.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

The complete notice is preserved in every language port. See [workload.json](workload.json) and the independent [oracle](../../mccat_08_main_oracle.py).

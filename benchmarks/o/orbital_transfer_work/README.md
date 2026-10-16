# Orbital transfer work

This benchmark preserves the pinned Python routine's gravitational work calculation, `((G * M * m) / 2) * (1 / r_initial - 1 / r_final)`, with `G = 6.67430e-11`. The source formats the numeric result as a three-decimal scientific-notation string; the shared benchmark contract measures the underlying numeric work as one little-endian binary64 value so output formatting does not dominate the kernel.

Input is `[central_mass, object_mass, initial_radius, final_radius]`, with masses bounded to ±1,000,000,000 kg and ±1,000,000 kg and radii in [1, 1,000,000,000] m. Invalid or out-of-domain inputs return -1. Runtime oracle: `orbital_transfer_work_oracle.py`.

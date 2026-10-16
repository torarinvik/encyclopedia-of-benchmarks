# N-body simulation

This benchmark follows the pinned Python `BodySystem.update_system` Euler step. Every body first accumulates gravitational acceleration from the other bodies using `distance = sqrt(dx² + dy² + softening)`. It then updates velocity by `force * (delta_time * time_factor)`. Only after all velocities have changed are positions updated from the new velocities, preserving the source's update order.

The input is `[body_count, step_count, delta_time_milli, gravity_milli, time_factor, softening_milli, (x, y, vx, vy, mass)*]`. Bounds are 2–4 bodies, 0–4 steps, delta time 0.001–1 seconds, gravity 0–1, time factor 1–10, softening 0.001–3, positions ±1000, velocities ±100, and masses 1–1000. Output is each body's final `[x,y,vx,vy]`, in body order, as little-endian binary64 values. The fixed positive softening prevents zero-distance singularities. The runtime oracle is `n_body_simulation_oracle.py`.

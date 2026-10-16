package ode_midpoint_euler

import "core:c"

MAX_STEPS :: 8
OUTPUT_BYTES :: 16

put_f64_le :: proc "contextless" (output: [^]u8, offset: usize, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
ode_midpoint_euler :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 4 do return -1
	steps, dt_quarters, u0, v0 := input[0], input[1], input[2], input[3]
	if steps < 1 || steps > MAX_STEPS || dt_quarters < 1 || dt_quarters > 4 ||
		u0 < -10 || u0 > 10 || v0 < -10 || v0 > 10 do return -1
	if output == nil || capacity < OUTPUT_BYTES do return -2

	dt := f64(dt_quarters) / 4.0
	half_dt := 0.5 * dt
	u, v := f64(u0), f64(v0)
	for step := i64(0); step < steps; step += 1 {
		midpoint_u := u + half_dt * v
		midpoint_v := v - half_dt * u
		next_u := u + dt * midpoint_v
		next_v := v - dt * midpoint_u
		u, v = next_u, next_v
	}
	put_f64_le(output, 0, u)
	put_f64_le(output, 8, v)
	return OUTPUT_BYTES
}

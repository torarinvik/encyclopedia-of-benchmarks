package full_wave_rectifier

import "core:c"

OUTPUT_BYTES :: i64(48)

store_f64_le :: proc(output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

// Evaluate the six pinned full-wave rectifier helper formulas.
@(export)
full_wave_rectifier :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length != 5 do return -1
	rf_i, rs_i, rl_i := values[0], values[1], values[2]
	vm_i, im_i := values[3], values[4]
	if rf_i < 0 || rf_i > 1000000 || rs_i < 0 || rs_i > 1000000 ||
		rl_i < 1 || rl_i > 1000000 || vm_i < -1000000 || vm_i > 1000000 ||
		im_i < -1000000 || im_i > 1000000 do return -1
	if output == nil || output_capacity < 48 do return -2

	rf, rs, rl := f64(rf_i), f64(rs_i), f64(rl_i)
	vm, im := f64(vm_i), f64(im_i)
	store_f64_le(output, 0, vm / (rf + rs + rl))
	store_f64_le(output, 8, 2.0 * im * 0.318)
	store_f64_le(output, 16, 2.0 * 0.318 * vm)
	store_f64_le(output, 24, vm / rl)
	store_f64_le(output, 32, im * 0.707)
	store_f64_le(output, 40, vm * 0.707)
	return OUTPUT_BYTES
}

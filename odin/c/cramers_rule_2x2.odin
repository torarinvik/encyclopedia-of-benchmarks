package cramers_rule_2x2

import "core:c"

LIMIT :: i64(1_000_000)

write_f64_le :: proc(output: [^]u8, offset: c.size_t, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + c.size_t(byte)] = u8(bits >> u64(8 * byte))
	}
}

@(export)
cramers_rule_2x2 :: proc "c" (v: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if v == nil || length != 6 do return -1
	for i := 0; i < 6; i += 1 do if v[i] < -LIMIT || v[i] > LIMIT do return -1
	a1, b1, c1, a2, b2, c2 := v[0], v[1], v[2], v[3], v[4], v[5]
	d, dx, dy := a1*b2-a2*b1, c1*b2-c2*b1, a1*c2-a2*c1
	if d == 0 do return -1
	if output == nil || capacity < 16 do return -2
	write_f64_le(output, 0, f64(dx)/f64(d))
	write_f64_le(output, 8, f64(dy)/f64(d))
	return 2
}

package shree_dharacharya_formula

import "core:c"
import "core:math"

write_f64_le :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> u64(byte * 8)) }
}

@(export)
shree_dharacharya_formula :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	for index := 0; index < 3; index += 1 {
		if input[index] < -1000000 || input[index] > 1000000 do return -1
	}
	if input[0] == 0 do return -1
	a := f64(input[0])
	b := f64(input[1])
	c_value := f64(input[2])
	discriminant := b * b - 4.0 * a * c_value
	if discriminant < 0.0 do return -1
	if output == nil || capacity < 16 do return -2
	root := math.sqrt(discriminant)
	denominator := 2.0 * a
	first := (-b + root) / denominator
	second := (-b - root) / denominator
	write_f64_le(output, 0, first)
	write_f64_le(output, 8, second)
	return 16
}

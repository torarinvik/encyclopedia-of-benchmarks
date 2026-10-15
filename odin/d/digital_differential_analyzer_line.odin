package digital_differential_analyzer_line

import "core:c"

round_ties_to_even :: proc(value: f64) -> i64 {
	lower := i64(value)
	if f64(lower) > value { lower -= 1 }
	fraction := value - f64(lower)
	if fraction > 0.5 || (fraction == 0.5 && lower % 2 != 0) { lower += 1 }
	return lower
}

write_i32_le :: proc(output: [^]u8, position: ^int, value: i64) {
	bits := u32(i32(value))
	for shift := 0; shift < 32; shift += 8 {
		output[position^] = u8((bits >> u32(shift)) & 255)
		position^ += 1
	}
}

@(export)
digital_differential_analyzer_line :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length != 4 do return -1
	for index := c.size_t(0); index < 4; index += 1 {
		if values[index] < -1000000 || values[index] > 1000000 do return -1
	}
	dx := values[2] - values[0]
	dy := values[3] - values[1]
	abs_dx := dx
	abs_dy := dy
	if abs_dx < 0 { abs_dx = -abs_dx }
	if abs_dy < 0 { abs_dy = -abs_dy }
	steps := abs_dx
	if abs_dy > steps { steps = abs_dy }
	if steps == 0 || steps > 4096 do return -1
	output_bytes := c.size_t(steps * 8)
	if output_capacity < output_bytes do return -2
	x_increment := f64(dx) / f64(steps)
	y_increment := f64(dy) / f64(steps)
	x := f64(values[0])
	y := f64(values[1])
	position := 0
	for step := i64(0); step < steps; step += 1 {
		x += x_increment
		y += y_increment
		write_i32_le(output, &position, round_ties_to_even(x))
		write_i32_le(output, &position, round_ties_to_even(y))
	}
	return i64(output_bytes)
}

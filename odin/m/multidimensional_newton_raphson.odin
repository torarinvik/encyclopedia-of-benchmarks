package multidimensional_newton_raphson

import "core:c"
import "core:math"

Min_Coordinate :: i64(900)
Max_Coordinate :: i64(1500)
Max_Updates :: i64(8)

store_i64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: i64) {
	bits := transmute(u64)value
	for byte: c.size_t = 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

round_nano :: proc "contextless" (value: f64) -> i64 {
	magnitude := if value < 0.0 { 0.0 - value } else { value }
	rounded := i64(math.floor_f64(magnitude * 1_000_000_000.0 + 0.5))
	return if value < 0.0 { -rounded } else { rounded }
}

@(export)
multidimensional_newton_raphson :: proc "c" (input: [^]i64,
	length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 4 do return -1
	if length != 3 do return -1
	x_milli, y_milli, updates := input[0], input[1], input[2]
	if x_milli < Min_Coordinate || x_milli > Max_Coordinate ||
		y_milli < Min_Coordinate || y_milli > Max_Coordinate ||
		updates < 1 || updates > Max_Updates do return -1
	if output == nil || capacity < 16 do return -2

	x := f64(x_milli) / 1000.0
	y := f64(y_milli) / 1000.0
	for step: i64 = 0; step < updates; step += 1 {
		f1 := x*x + y - 3.0
		f2 := x + y*y - 3.0
		determinant := 4.0*x*y - 1.0
		dx := (2.0*y*f1 - f2) / determinant
		dy := (2.0*x*f2 - f1) / determinant
		x -= dx
		y -= dy
	}
	store_i64_le(output, 0, round_nano(x))
	store_i64_le(output, 8, round_nano(y))
	return 16
}

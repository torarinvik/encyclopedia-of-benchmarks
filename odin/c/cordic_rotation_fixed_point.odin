package cordic_rotation_fixed_point

import "core:c"

OUTPUT_BYTES :: 24
SCALE :: i64(1_000_000_000)
HALF_PI :: i64(1_570_796_327)
ANGLES :: [15]i64{
	785_398_163, 463_647_609, 244_978_663, 124_354_995, 62_418_810,
	31_239_833, 15_623_729, 7_812_341, 3_906_230, 1_953_123,
	976_562, 488_281, 244_141, 122_070, 61_035,
}

shift_floor :: proc "contextless" (value: i64, shift: int) -> i64 {
	if shift == 0 do return value
	divisor := i64(1) << u64(shift)
	if value >= 0 do return value / divisor
	return -((-value + divisor - 1) / divisor)
}

put_f64_le :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(byte * 8))
	}
}

@(export)
cordic_rotation_fixed_point :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 3 do return -1
	if length != 2 do return -1
	angle, stages := input[0], input[1]
	if angle < -3_141_592_653 || angle > 3_141_592_653 || stages < 1 || stages > 16 do return -1
	if output == nil || capacity < OUTPUT_BYTES do return -2

	x, y, z := SCALE, i64(0), angle
	direction := i64(1)
	if z < 0 do direction = -1
	if direction > 0 {
		old_x := x
		x, y = -y, old_x
	} else {
		old_x := x
		x, y = y, -old_x
	}
	z -= direction * HALF_PI
	for shift := 0; shift < int(stages-1); shift += 1 {
		direction = 1
		if z < 0 do direction = -1
		old_x, old_y := x, y
		x = old_x - direction * shift_floor(old_y, shift)
		y = old_y + direction * shift_floor(old_x, shift)
		z -= direction * ANGLES[shift]
	}

	scale := 1_000_000_000.0
	put_f64_le(output, 0, f64(x) / scale)
	put_f64_le(output, 8, f64(y) / scale)
	put_f64_le(output, 16, f64(z) / scale)
	return OUTPUT_BYTES
}

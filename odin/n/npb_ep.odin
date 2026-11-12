package npb_ep

import "core:c"
import "core:math"

MAX_PAIRS :: 4096
MODULUS_MASK :: u64(70_368_744_177_663)
WORD_MASK :: u64(8_388_607)
MULTIPLIER :: u64(1_220_703_125)
MODULUS_SCALE :: 70_368_744_177_664.0

is_bounded_integer :: proc "contextless" (value, minimum, maximum: f64) -> bool {
	return math.is_finite(value) && math.trunc(value) == value && value >= minimum && value <= maximum
}

advance_state :: proc "contextless" (state: u64) -> u64 {
	low := state & WORD_MASK
	high := state >> 23
	multiplier_low := MULTIPLIER & WORD_MASK
	multiplier_high := MULTIPLIER >> 23
	low_product := low * multiplier_low
	cross := (low * multiplier_high + high * multiplier_low) & WORD_MASK
	return (low_product + (cross << 23)) & MODULUS_MASK
}

@(export)
npb_ep :: proc "c" (input: [^]f64, length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	if !is_bounded_integer(input[0], 1.0, f64(MAX_PAIRS)) ||
		!is_bounded_integer(input[1], 1.0, 70_368_744_177_663.0) do return -1
	pair_count := int(input[0])
	if output == nil || capacity < 12 do return -2

	state := u64(input[1])
	histogram: [10]u64
	sum_x, sum_y: f64 = 0.0, 0.0
	for pair := 0; pair < pair_count; pair += 1 {
		state = advance_state(state)
		x := 2.0 * (f64(state) / MODULUS_SCALE) - 1.0
		state = advance_state(state)
		y := 2.0 * (f64(state) / MODULUS_SCALE) - 1.0
		radius_squared := x * x + y * y
		if radius_squared <= 0.0 || radius_squared > 1.0 do continue
		scale := math.sqrt_f64(-2.0 * math.ln_f64(radius_squared) / radius_squared)
		normal_x, normal_y := x * scale, y * scale
		extent_x := if normal_x < 0.0 then -normal_x else normal_x
		extent_y := if normal_y < 0.0 then -normal_y else normal_y
		extent := if extent_x > extent_y then extent_x else extent_y
		if extent < 10.0 do histogram[int(extent)] += 1
		sum_x += normal_x
		sum_y += normal_y
	}
	for bin := 0; bin < 10; bin += 1 { output[bin] = f64(histogram[bin]) }
	output[10], output[11] = sum_x, sum_y
	return 12
}

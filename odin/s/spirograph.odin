package spirograph

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 5
MAX_POINTS :: 32
MAX_OUTPUT_ELEMENTS :: 64

exact_integer :: proc(value: f64, minimum, maximum: i64) -> bool {
	if math.is_nan(value) || math.is_inf(value) || value < f64(minimum) || value > f64(maximum) do return false
	return f64(i64(value)) == value
}

@(export)
spirograph :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_INPUT_LENGTH do return -1
	if input_length != 4 do return -1
	if !exact_integer(input[0], 1, MAX_POINTS) do return -1
	points := int(input[0])
	marker_ratio, inner_ratio, rotations := input[1], input[2], input[3]
	if math.is_nan(marker_ratio) || math.is_inf(marker_ratio) || marker_ratio < 0 || marker_ratio > 1 do return -1
	if math.is_nan(inner_ratio) || math.is_inf(inner_ratio) || inner_ratio < 0.25 || inner_ratio > 0.75 do return -1
	if math.is_nan(rotations) || math.is_inf(rotations) || rotations < 0 || rotations > 10 do return -1

	delta := rotations * 2.0 * 3.14159265358979323846 / f64(points)
	k1 := 1.0 - inner_ratio
	staged: [MAX_OUTPUT_ELEMENTS]f64
	for index := 0; index < points; index += 1 {
		t := f64(index) * delta
		inner_angle := k1 * t / inner_ratio
		x := k1 * math.cos(t) + marker_ratio * inner_ratio * math.cos(inner_angle)
		y := k1 * math.sin(t) - marker_ratio * inner_ratio * math.sin(inner_angle)
		if math.is_nan(x) || math.is_inf(x) || math.is_nan(y) || math.is_inf(y) do return -1
		staged[2*index], staged[2*index+1] = x, y
	}

	output_length := 2 * points
	if output == nil || capacity < c.size_t(output_length) do return -2
	for index := 0; index < output_length; index += 1 { output[index] = staged[index] }
	return i64(output_length)
}

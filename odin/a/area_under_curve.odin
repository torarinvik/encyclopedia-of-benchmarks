package area_under_curve

import "core:c"

MAX_STEPS :: 10000
MAX_COORD_MILLI :: i64(100000)
OUTPUT_SCALE :: f64(1000000.0)

sample_value :: proc(function_id: i64, x: f64) -> f64 {
	if function_id == 0 do return 5.0
	if function_id == 1 do return x
	return x * x
}

@(export)
area_under_curve :: proc "contextless" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 4 do return -1
	function_id := input[0]
	start_milli := input[1]
	end_milli := input[2]
	steps := input[3]
	if function_id < 0 || function_id > 2 || start_milli < 0 || start_milli > MAX_COORD_MILLI ||
		end_milli < 0 || end_milli > MAX_COORD_MILLI || steps < 1 || steps > MAX_STEPS do return -1
	low_milli := min(start_milli, end_milli)
	high_milli := max(start_milli, end_milli)
	start := f64(low_milli) / 1000.0
	ending := f64(high_milli) / 1000.0
	width := (ending - start) / f64(steps)
	x1 := start
	y1 := sample_value(function_id, x1)
	area := f64(0)
	for index := i64(0); index < steps; index += 1 {
		x2 := x1 + width
		y2 := sample_value(function_id, x2)
		area += (y1 + y2) * width * 0.5
		x1 = x2
		y1 = y2
	}
	return i64(area*OUTPUT_SCALE + 0.5)
}

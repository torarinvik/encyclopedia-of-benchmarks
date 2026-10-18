package k_means_julia

import "core:c"

MAX_INPUT_LENGTH :: 10
MAX_MOVES :: 64
CENTER_SCALE :: f64(256.0)
CENTER_BIAS :: i64(4097)
CENTER_BASE :: i64(8194)

@(export)
k_means_julia :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 3 || input[0] > 8 do return -1
	n := int(input[0])
	if int(length) != n + 1 do return -1

	var points: [8]f64
	for index := 0; index < n; index += 1 {
		coordinate := input[index+1]
		if coordinate < -16 || coordinate > 16 || (index > 0 && input[index] >= coordinate) do return -1
		points[index] = f64(coordinate)
	}

	var centers := [2]f64{points[0], points[n/2]}
	for _ in 0 ..< MAX_MOVES {
		var sums: [2]f64
		var counts: [2]int
		for index := 0; index < n; index += 1 {
			d0 := points[index] - centers[0]
			d1 := points[index] - centers[1]
			cluster := 0
			if d1*d1 < d0*d0 do cluster = 1
			sums[cluster] += points[index]
			counts[cluster] += 1
		}
		if counts[0] == 0 || counts[1] == 0 do return -1
		moved := [2]f64{sums[0]/f64(counts[0]), sums[1]/f64(counts[1])}
		if moved[0] == centers[0] && moved[1] == centers[1] {
			code0 := i64(moved[0]*CENTER_SCALE)+CENTER_BIAS
			code1 := i64(moved[1]*CENTER_SCALE)+CENTER_BIAS
			if code0 < 1 || code0 > 8193 || code1 < 1 || code1 > 8193 do return -1
			return code0*CENTER_BASE+code1
		}
		centers = moved
	}
	return -2
}

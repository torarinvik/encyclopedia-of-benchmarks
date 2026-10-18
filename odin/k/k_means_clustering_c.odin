package k_means_clustering_c

import "core:c"

MAX_INPUT_LENGTH :: 18
MAX_MOVES :: 64
CENTER_SCALE :: f64(256.0)
CENTER_BIAS :: i64(4097)
CENTER_BASE :: i64(8194)

@(export)
k_means_clustering_c :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 3 || input[0] > 8 do return -1
	n := int(input[0])
	if int(length) != 1 + 2*n do return -1

	var labels: [8]i64
	has_zero, has_one := false, false
	for index := 0; index < n; index += 1 {
		label := input[index+1]
		coordinate := input[1+n+index]
		if label != 0 && label != 1 do return -1
		labels[index] = label
		if label == 0 do has_zero = true
		if label == 1 do has_one = true
		if coordinate < -16 || coordinate > 16 || (index > 0 && input[n+index] >= coordinate) do return -1
	}
	if !has_zero || !has_one do return -1

	for _ in 0 ..< MAX_MOVES {
		var sums: [2]f64
		var counts: [2]int
		for index := 0; index < n; index += 1 {
			cluster := int(labels[index])
			sums[cluster] += f64(input[1+n+index])
			counts[cluster] += 1
		}
		if counts[0] == 0 || counts[1] == 0 do return -1
		centers := [2]f64{sums[0]/f64(counts[0]), sums[1]/f64(counts[1])}

		var next_labels: [8]i64
		changed := 0
		for index := 0; index < n; index += 1 {
			point := f64(input[1+n+index])
			d0 := point-centers[0]
			d1 := point-centers[1]
			if d1*d1 < d0*d0 do next_labels[index] = 1
			if next_labels[index] != labels[index] do changed += 1
		}
		labels = next_labels
		if changed == 0 {
			code0 := i64(centers[0]*CENTER_SCALE)+CENTER_BIAS
			code1 := i64(centers[1]*CENTER_SCALE)+CENTER_BIAS
			if code0 < 1 || code0 > 8193 || code1 < 1 || code1 > 8193 do return -1
			return code0*CENTER_BASE+code1
		}
	}
	return -2
}

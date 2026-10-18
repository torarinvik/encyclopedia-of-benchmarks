package kmeans_rust

import "core:c"

MAX_INPUT_LENGTH :: 10
MAX_MOVES :: 256

@(export)
kmeans_rust :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 2 || input[0] > 8 do return -1
	n := int(input[0])
	if int(length) != n + 1 do return -1

	var points: [8]f64
	for index := 0; index < n; index += 1 {
		coordinate := input[index+1]
		if coordinate < -16 || coordinate > 16 || (index > 0 && input[index] >= coordinate) do return -1
		points[index] = f64(coordinate)
	}

	var centers := [2]f64{points[0], points[n/2]}
	var labels: [8]i64
	for index := 0; index < n; index += 1 {
		d0 := points[index] - centers[0]
		d1 := points[index] - centers[1]
		if d1*d1 < d0*d0 do labels[index] = 1
	}

	for _ in 0 ..< MAX_MOVES {
		var sums: [2]f64
		var counts: [2]int
		for index := 0; index < n; index += 1 {
			cluster := int(labels[index])
			sums[cluster] += points[index]
			counts[cluster] += 1
		}
		if counts[0] == 0 || counts[1] == 0 do return -1
		centers[0] = sums[0] / f64(counts[0])
		centers[1] = sums[1] / f64(counts[1])

		var next_labels: [8]i64
		unchanged := true
		for index := 0; index < n; index += 1 {
			d0 := points[index] - centers[0]
			d1 := points[index] - centers[1]
			if d1*d1 < d0*d0 do next_labels[index] = 1
			if next_labels[index] != labels[index] do unchanged = false
		}
		if unchanged {
			packed := i64(0)
			for index := 0; index < n; index += 1 { packed |= next_labels[index] << index }
			return packed
		}
		labels = next_labels
	}
	return -2
}

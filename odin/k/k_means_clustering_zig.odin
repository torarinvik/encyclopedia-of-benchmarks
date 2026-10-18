package k_means_clustering_zig

import "core:c"

MAX_INPUT_LENGTH :: 10
MAX_MOVES :: 64
CENTER_BIAS :: i64(4097)
CENTER_BASE :: i64(8194)

@(export)
k_means_clustering_zig :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 2 || input[0] > 8 do return -1
	point_count := int(input[0])
	if int(length) != point_count + 1 do return -1

	var points: [8]f32
	for index := 0; index < point_count; index += 1 {
		coordinate := input[index+1]
		if coordinate < -16 || coordinate > 16 || (index > 0 && input[index] >= coordinate) do return -1
		points[index] = f32(coordinate)
	}

	var centers := [2]f32{points[0], points[1]}
	var old_counts: [2]int
	for move := 0; move < MAX_MOVES; move += 1 {
		var sums: [2]f32
		var counts: [2]int
		for index := 0; index < point_count; index += 1 {
			first_delta := points[index] - centers[0]
			second_delta := centers[1] - points[index]
			first_distance := first_delta * first_delta
			second_distance := second_delta * second_delta
			cluster := 0
			if second_distance < first_distance do cluster = 1
			sums[cluster] = sums[cluster] + points[index]
			counts[cluster] += 1
		}
		if counts[0] == 0 || counts[1] == 0 do return -1
		moved := [2]f32{sums[0] / f32(counts[0]), sums[1] / f32(counts[1])}
		if moved[0] == centers[0] && moved[1] == centers[1] &&
			counts[0] == old_counts[0] && counts[1] == old_counts[1] {
			code0 := i64(moved[0] * 256.0) + CENTER_BIAS
			code1 := i64(moved[1] * 256.0) + CENTER_BIAS
			if code0 < 1 || code0 > 8193 || code1 < 1 || code1 > 8193 do return -1
			return (code0 * CENTER_BASE + code1) * 81 + i64(counts[0]) * 9 + i64(counts[1])
		}
		centers = moved
		old_counts = counts
	}
	return -2
}

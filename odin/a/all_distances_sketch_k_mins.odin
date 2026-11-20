package all_distances_sketch_k_mins

import "core:c"

MAX_N :: 6
MAX_ASSIGNMENTS :: 3
MAX_INPUT :: 27
MAX_WORDS :: 73

put_i64_le :: proc "contextless" (output: [^]u8, word: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[word * 8 + byte] = u8((bits >> (8 * byte)) & 255)
	}
}

@(export)
all_distances_sketch_k_mins :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n0, assignments0 := input[0], input[1]
	if n0 < 1 || n0 > MAX_N || assignments0 < 1 || assignments0 > MAX_ASSIGNMENTS do return -1
	n, assignments := int(n0), int(assignments0)
	if length != c.size_t(2 + n + assignments * n) do return -1

	var distances: [MAX_N]i64
	for item := 0; item < n; item += 1 {
		distance := input[2 + item]
		if distance < 0 || distance > 1000000 || (item > 0 && distances[item - 1] >= distance) do return -1
		distances[item] = distance
	}
	var ranks: [MAX_ASSIGNMENTS * MAX_N]i64
	for assignment := 0; assignment < assignments; assignment += 1 {
		var seen: [MAX_N]bool
		for item := 0; item < n; item += 1 {
			rank := input[2 + n + assignment * n + item]
			if rank < 0 || rank >= n0 || seen[int(rank)] do return -1
			seen[int(rank)] = true
			ranks[assignment * MAX_N + item] = rank
		}
	}

	var staged: [MAX_WORDS]i64
	count := 0
	for assignment := 0; assignment < assignments; assignment += 1 {
		best_rank := n0
		for item := 0; item < n; item += 1 {
			rank := ranks[assignment * MAX_N + item]
			if rank < best_rank {
				staged[1 + 4 * count] = i64(assignment)
				staged[2 + 4 * count] = i64(item)
				staged[3 + 4 * count] = rank
				staged[4 + 4 * count] = distances[item]
				count += 1
				best_rank = rank
			}
		}
	}
	staged[0] = i64(count)
	words, bytes := 1 + 4 * count, c.size_t(8 * (1 + 4 * count))
	if output == nil || capacity < bytes do return -2
	for word := 0; word < words; word += 1 { put_i64_le(output, word, staged[word]) }
	return i64(bytes)
}

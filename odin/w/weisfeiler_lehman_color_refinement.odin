package weisfeiler_lehman_color_refinement

import "core:c"

MAX_VERTICES :: 8
MAX_INPUT_LENGTH :: 9
INVALID_RESULT :: i64 = -1
DEGREE_COLOR_PLACE :: i64 = 43046721

bit_count :: proc(value_input: i64) -> int {
	value := value_input
	count := 0
	for value != 0 {
		count += int(value & 1)
		value >>= 1
	}
	return count
}

@(export)
weisfeiler_lehman_color_refinement :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH+1 do return INVALID_RESULT
	if input[0] < 0 || input[0] > MAX_VERTICES do return INVALID_RESULT
	n := int(input[0])
	if int(length) != 1+n do return INVALID_RESULT

	allowed := (i64(1) << n)-1
	var adjacency: [MAX_VERTICES]i64
	var colors: [MAX_VERTICES]i64
	var next_colors: [MAX_VERTICES]i64
	class_count := 0
	for vertex := 0; vertex < n; vertex += 1 {
		mask := input[1+vertex]
		if mask < 0 || (mask & ~allowed) != 0 || (mask & (i64(1) << vertex)) != 0 do return INVALID_RESULT
		adjacency[vertex] = mask
		colors[vertex] = i64(bit_count(mask))
		first_degree := true
		for prior := 0; prior < vertex; prior += 1 {
			if colors[prior] == colors[vertex] { first_degree = false }
			if ((adjacency[vertex] >> prior) & 1) != ((adjacency[prior] >> vertex) & 1) do return INVALID_RESULT
		}
		if first_degree { class_count += 1 }
	}
	if n == 0 do return 0

	for {
		var keys: [MAX_VERTICES]i64
		var unique_keys: [MAX_VERTICES]i64
		unique_count := 0
		for vertex := 0; vertex < n; vertex += 1 {
			var neighbor_colors: [MAX_VERTICES]i64
			neighbor_count := 0
			for neighbor := 0; neighbor < n; neighbor += 1 {
				if (adjacency[vertex] & (i64(1) << neighbor)) == 0 do continue
				value := colors[neighbor]
				position := neighbor_count
				for position > 0 && neighbor_colors[position-1] > value {
					neighbor_colors[position] = neighbor_colors[position-1]
					position -= 1
				}
				neighbor_colors[position] = value
				neighbor_count += 1
			}
			suffix: i64 = 0
			for slot := 0; slot < MAX_VERTICES; slot += 1 {
				suffix = suffix*9
				if slot < neighbor_count { suffix += neighbor_colors[slot]+1 }
			}
			keys[vertex] = colors[vertex]*DEGREE_COLOR_PLACE+suffix
			seen := false
			for prior := 0; prior < vertex; prior += 1 {
				if keys[prior] == keys[vertex] { seen = true }
			}
			if !seen { unique_keys[unique_count] = keys[vertex]; unique_count += 1 }
		}

		for index := 1; index < unique_count; index += 1 {
			value := unique_keys[index]
			position := index
			for position > 0 && unique_keys[position-1] > value {
				unique_keys[position] = unique_keys[position-1]
				position -= 1
			}
			unique_keys[position] = value
		}
		for vertex := 0; vertex < n; vertex += 1 {
			rank := 0
			for unique_keys[rank] != keys[vertex] { rank += 1 }
			next_colors[vertex] = i64(rank)
		}
		for vertex := 0; vertex < n; vertex += 1 { colors[vertex] = next_colors[vertex] }
		if unique_count == class_count { break }
		class_count = unique_count
	}

	packed: i64 = 0
	place: i64 = 1
	for vertex := 0; vertex < n; vertex += 1 {
		packed += colors[vertex]*place
		place *= 9
	}
	return packed
}

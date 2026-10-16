package bellman_ford_pair

import "core:c"

MAX_VERTICES :: 64
MAX_INPUT_EDGES :: 256
MAX_NORMALIZED_EDGES :: 128
MAX_WEIGHT :: i64(1_000)
RECORD_BYTES :: 24

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> (byte * 8)) & 0xFF)
	}
}

write_record :: proc(output: [^]u8, capacity: c.size_t, status, target_reachable, distance: i64) -> i64 {
	if output == nil || capacity < RECORD_BYTES do return -2
	store_i64_le(output, 0, status)
	store_i64_le(output, 8, target_reachable)
	store_i64_le(output, 16, distance)
	return i64(RECORD_BYTES)
}

@(export)
bellman_ford_pair :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 do return -1
	nv, mv, source_value, target_value := input[0], input[1], input[2], input[3]
	if nv < 1 || nv > MAX_VERTICES || mv < 0 || mv > MAX_INPUT_EDGES do return -1
	n, input_edges := int(nv), int(mv)
	if source_value < 0 || source_value >= nv || target_value < 0 || target_value >= nv ||
		length != c.size_t(4 + 3 * input_edges) do return -1

	var matrix_weights: [MAX_VERTICES * MAX_VERTICES]i64
	var matrix_present: [MAX_VERTICES * MAX_VERTICES]bool
	normalized_count := 0
	for edge := 0; edge < input_edges; edge += 1 {
		from_value, to_value, weight_value := input[4 + 3 * edge], input[5 + 3 * edge], input[6 + 3 * edge]
		if from_value < 0 || from_value >= nv || to_value < 0 || to_value >= nv ||
			weight_value < -MAX_WEIGHT || weight_value > MAX_WEIGHT do return -1
		key := int(from_value) * n + int(to_value)
		if !matrix_present[key] {
			matrix_present[key] = true
			normalized_count += 1
			if normalized_count > MAX_NORMALIZED_EDGES do return -1
		}
		matrix_weights[key] = weight_value
	}

	var from: [MAX_NORMALIZED_EDGES]int
	var to: [MAX_NORMALIZED_EDGES]int
	var weight: [MAX_NORMALIZED_EDGES]i64
	edge_count := 0
	for origin := 0; origin < n; origin += 1 {
		for destination := 0; destination < n; destination += 1 {
			key := origin * n + destination
			if !matrix_present[key] do continue
			from[edge_count] = origin
			to[edge_count] = destination
			weight[edge_count] = matrix_weights[key]
			edge_count += 1
		}
	}

	source, target := int(source_value), int(target_value)
	var distance: [MAX_VERTICES]i64
	var reachable: [MAX_VERTICES]bool
	reachable[source] = true
	for round := 0; round < n; round += 1 {
		changed := false
		for edge := 0; edge < edge_count; edge += 1 {
			if !reachable[from[edge]] do continue
			candidate := distance[from[edge]] + weight[edge]
			if !reachable[to[edge]] || candidate < distance[to[edge]] {
				distance[to[edge]] = candidate
				reachable[to[edge]] = true
				changed = true
			}
		}
		if !changed do break
	}
	for edge := 0; edge < edge_count; edge += 1 {
		if reachable[from[edge]] && distance[to[edge]] > distance[from[edge]] + weight[edge] {
			return write_record(output, capacity, -1, 0, 0)
		}
	}
	target_reachable := i64(0)
	target_distance := i64(0)
	if reachable[target] {
		target_reachable = 1
		target_distance = distance[target]
	}
	return write_record(output, capacity, 0, target_reachable, target_distance)
}

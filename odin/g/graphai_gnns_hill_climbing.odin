package graphai_gnns_hill_climbing

import "core:c"

MAX_N :: 16
MAX_D :: 4
MAX_INPUT :: c.size_t(89)
MAX_PARSEABLE :: c.size_t(90)
COORD_LIMIT :: i64(100)
DISTANCE_RADIX :: i64(160001)

@(export)
graphai_gnns_hill_climbing :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 5 || length > MAX_PARSEABLE do return -1
	n_value := input[0]
	d_value := input[1]
	start_value := input[2]
	e_value := input[3]
	t_value := input[4]
	if n_value < 2 || n_value > MAX_N || d_value < 1 || d_value > MAX_D do return -1
	if start_value < 0 || start_value >= n_value || e_value < 1 || e_value >= n_value do return -1
	if t_value < 0 || t_value > 16 do return -1
	n := int(n_value)
	d := int(d_value)
	if length != c.size_t(5 + n * d + n + d) || length > MAX_INPUT do return -1

	var coordinates: [MAX_N * MAX_D]i64
	for index := 0; index < n * d; index += 1 {
		coordinate := input[5 + index]
		if coordinate < -COORD_LIMIT || coordinate > COORD_LIMIT do return -1
		coordinates[index] = coordinate
	}
	mask_offset := 5 + n * d
	allowed := (i64(1) << n) - 1
	var masks: [MAX_N]i64
	for vertex := 0; vertex < n; vertex += 1 {
		mask := input[mask_offset + vertex]
		if mask < 0 || (mask & ~allowed) != 0 || (mask & (i64(1) << vertex)) != 0 do return -1
		masks[vertex] = mask
	}
	var query: [MAX_D]i64
	for axis := 0; axis < d; axis += 1 {
		coordinate := input[mask_offset + n + axis]
		if coordinate < -COORD_LIMIT || coordinate > COORD_LIMIT do return -1
		query[axis] = coordinate
	}

	current := int(start_value)
	current_distance := i64(0)
	for axis := 0; axis < d; axis += 1 {
		delta := coordinates[current * d + axis] - query[axis]
		current_distance += delta * delta
	}
	evaluations := i64(1)
	moves := i64(0)
	for step := 0; step < int(t_value); step += 1 {
		best_vertex := current
		best_distance := current_distance
		inspected := i64(0)
		for vertex := 0; vertex < n; vertex += 1 {
			if (masks[current] & (i64(1) << vertex)) == 0 do continue
			distance := i64(0)
			for axis := 0; axis < d; axis += 1 {
				delta := coordinates[vertex * d + axis] - query[axis]
				distance += delta * delta
			}
			evaluations += 1
			inspected += 1
			if distance < best_distance || (distance == best_distance && vertex < best_vertex) {
				best_vertex = vertex
				best_distance = distance
			}
			if inspected == e_value do break
		}
		if best_distance >= current_distance do break
		current = best_vertex
		current_distance = best_distance
		moves += 1
	}
	return (((evaluations * 17 + moves) * 16 + i64(current)) * DISTANCE_RADIX + current_distance)
}

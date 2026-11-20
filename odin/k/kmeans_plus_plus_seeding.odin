package kmeans_plus_plus_seeding

import "core:c"

MAX_POINTS :: 32
MAX_DIMENSION :: 4
MAX_CENTERS :: 8
MAX_INPUT_LENGTH :: 140

squared_distance :: proc(coordinates: [^]i64, dimension: int,
	row: int, center: int) -> i64 {
	distance: i64 = 0
	for axis := 0; axis < dimension; axis += 1 {
		difference := coordinates[row * dimension + axis] - coordinates[center * dimension + axis]
		distance += difference * difference
	}
	return distance
}

row_is_selected :: proc(centers: [^]i64, count: int, row: i64) -> bool {
	for index := 0; index < count; index += 1 {
		if centers[index] == row do return true
	}
	return false
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> (byte * 8)) & 255)
	}
}

@(export)
kmeans_plus_plus_seeding :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT_LENGTH do return -1
	point_count_value, dimension_value := input[0], input[1]
	center_count_value, first_row := input[2], input[3]
	if point_count_value < 1 || point_count_value > MAX_POINTS
		|| dimension_value < 1 || dimension_value > MAX_DIMENSION
		|| center_count_value < 1 || center_count_value > MAX_CENTERS
		|| center_count_value > point_count_value
		|| first_row < 0 || first_row >= point_count_value do return -1

	point_count := int(point_count_value)
	dimension := int(dimension_value)
	center_count := int(center_count_value)
	coordinate_count := point_count * dimension
	draw_offset := 4 + coordinate_count
	if length != c.size_t(draw_offset + center_count - 1) do return -1

	coordinates: [128]i64 = {}
	for index := 0; index < coordinate_count; index += 1 {
		coordinate := input[4 + index]
		if coordinate < -16 || coordinate > 16 do return -1
		coordinates[index] = coordinate
	}

	centers: [8]i64 = {}
	nearest: [32]i64 = {}
	centers[0] = first_row
	for row := 0; row < point_count; row += 1 {
		nearest[row] = squared_distance(&coordinates[0], dimension, row, int(first_row))
	}

	for step := 0; step < center_count - 1; step += 1 {
		draw := input[draw_offset + step]
		var total_weight: i64 = 0
		for row := 0; row < point_count; row += 1 { total_weight += nearest[row] }
		var chosen: i64 = -1
		if total_weight == 0 {
			if draw != 0 do return -1
			for row := 0; row < point_count; row += 1 {
				if !row_is_selected(&centers[0], step + 1, i64(row)) {
					chosen = i64(row)
					break
				}
			}
		} else {
			if draw < 0 || draw >= total_weight do return -1
			var cumulative: i64 = 0
			for row := 0; row < point_count; row += 1 {
				cumulative += nearest[row]
				if cumulative > draw { chosen = i64(row); break }
			}
		}
		if chosen < 0 do return -1
		centers[step + 1] = chosen
		for row := 0; row < point_count; row += 1 {
			distance := squared_distance(&coordinates[0], dimension, row, int(chosen))
			if distance < nearest[row] { nearest[row] = distance }
		}
	}

	output_bytes := center_count * 8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < center_count; index += 1 {
		store_i64_le(output, index * 8, centers[index])
	}
	return i64(output_bytes)
}

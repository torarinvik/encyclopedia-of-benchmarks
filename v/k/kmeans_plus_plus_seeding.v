module kmeans_plus_plus_seeding

fn squared_distance(coordinates []i64, dimension int, row int, center int) i64 {
	mut distance := i64(0)
	for axis in 0 .. dimension {
		difference := coordinates[row * dimension + axis] - coordinates[center * dimension + axis]
		distance += difference * difference
	}
	return distance
}

fn row_is_selected(centers []i64, row i64) bool {
	for center in centers {
		if center == row { return true }
	}
	return false
}

@[export: 'kmeans_plus_plus_seeding']
pub fn kmeans_plus_plus_seeding(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 140 { return -1 }
		point_count_value := input[0]
		dimension_value := input[1]
		center_count_value := input[2]
		first_row := input[3]
		if point_count_value < 1 || point_count_value > 32
			|| dimension_value < 1 || dimension_value > 4
			|| center_count_value < 1 || center_count_value > 8
			|| center_count_value > point_count_value
			|| first_row < 0 || first_row >= point_count_value { return -1 }

		point_count := int(point_count_value)
		dimension := int(dimension_value)
		center_count := int(center_count_value)
		coordinate_count := point_count * dimension
		draw_offset := 4 + coordinate_count
		if length != draw_offset + center_count - 1 { return -1 }

		mut coordinates := [128]i64{}
		for index in 0 .. coordinate_count {
			coordinate := input[4 + index]
			if coordinate < -16 || coordinate > 16 { return -1 }
			coordinates[index] = coordinate
		}

		mut centers := [8]i64{}
		mut nearest := [32]i64{}
		centers[0] = first_row
		for row in 0 .. point_count {
			nearest[row] = squared_distance(coordinates[..coordinate_count], dimension,
				row, int(first_row))
		}

		for step in 0 .. center_count - 1 {
			draw := input[draw_offset + step]
			mut total_weight := i64(0)
			for row in 0 .. point_count { total_weight += nearest[row] }
			mut chosen := i64(-1)
			if total_weight == 0 {
				if draw != 0 { return -1 }
				for row in 0 .. point_count {
					if !row_is_selected(centers[..step + 1], i64(row)) {
						chosen = i64(row)
						break
					}
				}
			} else {
				if draw < 0 || draw >= total_weight { return -1 }
				mut cumulative := i64(0)
				for row in 0 .. point_count {
					cumulative += nearest[row]
					if cumulative > draw {
						chosen = i64(row)
						break
					}
				}
			}
			if chosen < 0 { return -1 }

			centers[step + 1] = chosen
			for row in 0 .. point_count {
				distance := squared_distance(coordinates[..coordinate_count], dimension,
					row, int(chosen))
				if distance < nearest[row] { nearest[row] = distance }
			}
		}

		output_bytes := center_count * 8
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		for index in 0 .. center_count {
			bits := u64(centers[index])
			for byte in 0 .. 8 {
				output[index * 8 + byte] = u8((bits >> (byte * 8)) & 255)
			}
		}
		return i64(output_bytes)
	}
}

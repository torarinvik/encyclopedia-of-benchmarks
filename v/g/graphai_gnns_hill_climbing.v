module graphai_gnns_hill_climbing

const max_n = 16
const max_d = 4
const max_input = 89
const max_parseable = 90
const coord_limit = i64(100)
const distance_radix = i64(160001)

@[export: 'graphai_gnns_hill_climbing']
pub fn graphai_gnns_hill_climbing(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > usize(max_parseable) { return -1 }
		n_value, d_value, start_value := input[0], input[1], input[2]
		e_value, t_value := input[3], input[4]
		if n_value < 2 || n_value > max_n || d_value < 1 || d_value > max_d { return -1 }
		if start_value < 0 || start_value >= n_value || e_value < 1 || e_value >= n_value || t_value < 0 || t_value > 16 {
			return -1
		}
		n, d := int(n_value), int(d_value)
		if length != usize(5 + n * d + n + d) || length > usize(max_input) { return -1 }

		mut coordinates := [64]i64{}
		for index in 0 .. n * d {
			coordinate := input[5 + index]
			if coordinate < -coord_limit || coordinate > coord_limit { return -1 }
			coordinates[index] = coordinate
		}
		mask_offset := 5 + n * d
		allowed := (i64(1) << n) - 1
		mut masks := [16]i64{}
		for vertex in 0 .. n {
			mask := input[mask_offset + vertex]
			if mask < 0 || (mask & ~allowed) != 0 || (mask & (i64(1) << vertex)) != 0 { return -1 }
			masks[vertex] = mask
		}
		mut query := [4]i64{}
		for axis in 0 .. d {
			coordinate := input[mask_offset + n + axis]
			if coordinate < -coord_limit || coordinate > coord_limit { return -1 }
			query[axis] = coordinate
		}

		mut current := int(start_value)
		mut current_distance := i64(0)
		for axis in 0 .. d {
			delta := coordinates[current * d + axis] - query[axis]
			current_distance += delta * delta
		}
		mut evaluations := i64(1)
		mut moves := i64(0)
		for _ in 0 .. int(t_value) {
			mut best_vertex := current
			mut best_distance := current_distance
			mut inspected := i64(0)
			for vertex in 0 .. n {
				if (masks[current] & (i64(1) << vertex)) == 0 { continue }
				mut distance := i64(0)
				for axis in 0 .. d {
					delta := coordinates[vertex * d + axis] - query[axis]
					distance += delta * delta
				}
				evaluations++
				inspected++
				if distance < best_distance || (distance == best_distance && vertex < best_vertex) {
					best_vertex = vertex
					best_distance = distance
				}
				if inspected == e_value { break }
			}
			if best_distance >= current_distance { break }
			current = best_vertex
			current_distance = best_distance
			moves++
		}
		return (((evaluations * 17 + moves) * 16 + i64(current)) * distance_radix + current_distance)
	}
}

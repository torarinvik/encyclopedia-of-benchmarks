module kmeans_raw_r

import math

const invalid_result = -1.0e300
const max_input_length = 144

@[export: 'kmeans_raw_r']
pub fn kmeans_raw_r(values &i64, length usize) f64 {
	unsafe {
		if values == nil || length < 12 || length > usize(max_input_length) { return invalid_result }
		rows_value, dimensions_value, clusters_value, iteration_limit_value := values[0], values[1], values[2], values[3]
		if rows_value < 2 || rows_value > 32 || dimensions_value < 2 || dimensions_value > 4 ||
			clusters_value < 1 || clusters_value > 8 || clusters_value > rows_value / 2 ||
			iteration_limit_value < 1 || iteration_limit_value > 64 { return invalid_result }

		rows := int(rows_value)
		dimensions := int(dimensions_value)
		clusters := int(clusters_value)
		iteration_limit := int(iteration_limit_value)
		data_count := rows * dimensions
		data_start := 4 + clusters
		selector_start := data_start + data_count
		if int(length) != selector_start + 3 { return invalid_result }

		mut data := [128]f64{}
		for cluster in 0 .. clusters {
			initial_row := values[4 + cluster]
			if initial_row < 0 || initial_row >= rows_value { return invalid_result }
			for earlier in 0 .. cluster {
				if values[4 + earlier] == initial_row { return invalid_result }
			}
		}
		for index in 0 .. data_count {
			coordinate := values[data_start + index]
			if coordinate < -64 || coordinate > 64 { return invalid_result }
			data[index] = f64(coordinate)
		}

		field, arg0, arg1 := values[selector_start], values[selector_start + 1], values[selector_start + 2]
		if field < 0 || field > 2 { return invalid_result }
		if field == 0 && (arg0 < 0 || arg0 >= clusters_value || arg1 < 0 || arg1 >= dimensions_value) { return invalid_result }
		if field == 1 && (arg0 < 0 || arg0 >= rows_value || arg1 < 0 || arg1 >= clusters_value) { return invalid_result }
		if field == 2 && (arg0 < 0 || arg0 >= rows_value || arg1 != 0) { return invalid_result }

		mut centers := [32]f64{}
		for cluster in 0 .. clusters {
			initial_row := int(values[4 + cluster])
			for dimension in 0 .. dimensions {
				centers[cluster * dimensions + dimension] = data[initial_row * dimensions + dimension]
			}
		}

		mut distances := [256]f64{}
		mut assignments := [32]int{}
		mut stable := false
		for _ in 0 .. iteration_limit {
			mut member_counts := [8]int{}
			for row in 0 .. rows {
				mut best_cluster := 0
				for cluster in 0 .. clusters {
					mut squared_distance := f64(0)
					for dimension in 0 .. dimensions {
						difference := data[row * dimensions + dimension] - centers[cluster * dimensions + dimension]
						squared_distance += difference * difference
					}
					distances[row * clusters + cluster] = math.sqrt(squared_distance)
					if cluster > 0 && distances[row * clusters + cluster] < distances[row * clusters + best_cluster] {
						best_cluster = cluster
					}
				}
				assignments[row] = best_cluster
				member_counts[best_cluster]++
			}
			for cluster in 0 .. clusters {
				if member_counts[cluster] < 2 { return invalid_result }
			}

			mut updated := [32]f64{}
			for row in 0 .. rows {
				cluster := assignments[row]
				for dimension in 0 .. dimensions {
					updated[cluster * dimensions + dimension] += data[row * dimensions + dimension]
				}
			}
			stable = true
			for cluster in 0 .. clusters {
				for dimension in 0 .. dimensions {
					index := cluster * dimensions + dimension
					updated[index] /= f64(member_counts[cluster])
					if updated[index] != centers[index] { stable = false }
				}
			}
			for index in 0 .. clusters * dimensions { centers[index] = updated[index] }
			if stable { break }
		}
		if !stable { return invalid_result }

		if field == 0 { return centers[int(arg0) * dimensions + int(arg1)] }
		if field == 1 { return distances[int(arg0) * clusters + int(arg1)] }
		return f64(assignments[int(arg0)])
	}
}

package kmeans_raw_r

import "core:c"
import "core:math"

INVALID_RESULT :: -1.0e300
MAX_INPUT_LENGTH :: 144
MAX_ROWS :: 32
MAX_DIMENSIONS :: 4
MAX_CLUSTERS :: 8
MAX_ITERATIONS :: 64

@(export)
kmeans_raw_r :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 12 || length > c.size_t(MAX_INPUT_LENGTH) do return INVALID_RESULT
	rows_value, dimensions_value, clusters_value, iteration_limit_value := values[0], values[1], values[2], values[3]
	if rows_value < 2 || rows_value > MAX_ROWS || dimensions_value < 2 || dimensions_value > MAX_DIMENSIONS ||
		clusters_value < 1 || clusters_value > MAX_CLUSTERS || clusters_value > rows_value / 2 ||
		iteration_limit_value < 1 || iteration_limit_value > MAX_ITERATIONS do return INVALID_RESULT

	rows := int(rows_value)
	dimensions := int(dimensions_value)
	clusters := int(clusters_value)
	iteration_limit := int(iteration_limit_value)
	data_count := rows * dimensions
	data_start := 4 + clusters
	selector_start := data_start + data_count
	if int(length) != selector_start + 3 do return INVALID_RESULT

	data: [128]f64
	for cluster := 0; cluster < clusters; cluster += 1 {
		initial_row := values[4 + cluster]
		if initial_row < 0 || initial_row >= rows_value do return INVALID_RESULT
		for earlier := 0; earlier < cluster; earlier += 1 {
			if values[4 + earlier] == initial_row do return INVALID_RESULT
		}
	}
	for index := 0; index < data_count; index += 1 {
		coordinate := values[data_start + index]
		if coordinate < -64 || coordinate > 64 do return INVALID_RESULT
		data[index] = f64(coordinate)
	}

	field, arg0, arg1 := values[selector_start], values[selector_start + 1], values[selector_start + 2]
	if field < 0 || field > 2 do return INVALID_RESULT
	if field == 0 && (arg0 < 0 || arg0 >= clusters_value || arg1 < 0 || arg1 >= dimensions_value) do return INVALID_RESULT
	if field == 1 && (arg0 < 0 || arg0 >= rows_value || arg1 < 0 || arg1 >= clusters_value) do return INVALID_RESULT
	if field == 2 && (arg0 < 0 || arg0 >= rows_value || arg1 != 0) do return INVALID_RESULT

	centers: [32]f64
	for cluster := 0; cluster < clusters; cluster += 1 {
		initial_row := int(values[4 + cluster])
		for dimension := 0; dimension < dimensions; dimension += 1 {
			centers[cluster * dimensions + dimension] = data[initial_row * dimensions + dimension]
		}
	}

	distances: [256]f64
	assignments: [32]int
	stable := false
	for iteration := 0; iteration < iteration_limit; iteration += 1 {
		member_counts: [8]int
		for row := 0; row < rows; row += 1 {
			best_cluster := 0
			for cluster := 0; cluster < clusters; cluster += 1 {
				squared_distance := f64(0)
				for dimension := 0; dimension < dimensions; dimension += 1 {
					difference := data[row * dimensions + dimension] - centers[cluster * dimensions + dimension]
					squared_distance += difference * difference
				}
				distances[row * clusters + cluster] = math.sqrt(squared_distance)
				if cluster > 0 && distances[row * clusters + cluster] < distances[row * clusters + best_cluster] {
					best_cluster = cluster
				}
			}
			assignments[row] = best_cluster
			member_counts[best_cluster] += 1
		}
		for cluster := 0; cluster < clusters; cluster += 1 {
			if member_counts[cluster] < 2 do return INVALID_RESULT
		}

		updated: [32]f64
		for row := 0; row < rows; row += 1 {
			cluster := assignments[row]
			for dimension := 0; dimension < dimensions; dimension += 1 {
				updated[cluster * dimensions + dimension] += data[row * dimensions + dimension]
			}
		}
		stable = true
		for cluster := 0; cluster < clusters; cluster += 1 {
			for dimension := 0; dimension < dimensions; dimension += 1 {
				index := cluster * dimensions + dimension
				updated[index] /= f64(member_counts[cluster])
				if updated[index] != centers[index] do stable = false
			}
		}
		for index := 0; index < clusters * dimensions; index += 1 { centers[index] = updated[index] }
		if stable do break
	}
	if !stable do return INVALID_RESULT

	if field == 0 do return centers[int(arg0) * dimensions + int(arg1)]
	if field == 1 do return distances[int(arg0) * clusters + int(arg1)]
	return f64(assignments[int(arg0)])
}

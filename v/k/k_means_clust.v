fn exact_integer(value f64, minimum i64, maximum i64) bool {
	if !value.is_finite() || value < f64(minimum) || value > f64(maximum) { return false }
	return f64(i64(value)) == value
}

@[export: 'k_means_clust']
pub fn k_means_clust(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > 84 { return -1 }
		if !exact_integer(input[0], 1, 16) || !exact_integer(input[1], 1, 4) || !exact_integer(input[2], 1, 4) { return -1 }
		point_count := int(input[0])
		dimension := int(input[1])
		cluster_count := int(input[2])
		if cluster_count > point_count { return -1 }
		data_start := 3
		centroid_start := data_start + point_count*dimension
		expected_length := centroid_start + cluster_count*dimension
		if input_length != usize(expected_length) { return -1 }
		for i in data_start .. expected_length { if !exact_integer(input[i], -16, 16) { return -1 } }

		mut assignments := [16]int{}
		mut counts := [4]int{}
		mut sums := [4][4]i64{}
		for point in 0 .. point_count {
			mut best_cluster := 0
			mut best_distance := i64(0)
			for feature in 0 .. dimension {
				value := i64(input[data_start+point*dimension+feature])
				center := i64(input[centroid_start+feature])
				delta := value-center
				best_distance += delta*delta
			}
			for cluster in 1 .. cluster_count {
				mut distance := i64(0)
				for feature in 0 .. dimension {
					value := i64(input[data_start+point*dimension+feature])
					center := i64(input[centroid_start+cluster*dimension+feature])
					delta := value-center
					distance += delta*delta
				}
				if distance < best_distance { best_distance = distance; best_cluster = cluster }
			}
			assignments[point] = best_cluster
			counts[best_cluster]++
			for feature in 0 .. dimension { sums[best_cluster][feature] += i64(input[data_start+point*dimension+feature]) }
		}
		for cluster in 0 .. cluster_count { if counts[cluster] == 0 { return -1 } }
		output_length := point_count + cluster_count*dimension
		if output == nil || capacity < usize(output_length) { return -2 }
		for point in 0 .. point_count { output[point] = f64(assignments[point]) }
		for cluster in 0 .. cluster_count {
			for feature in 0 .. dimension {
				output[point_count+cluster*dimension+feature] = f64(sums[cluster][feature])/f64(counts[cluster])
			}
		}
		return i64(output_length)
	}
}

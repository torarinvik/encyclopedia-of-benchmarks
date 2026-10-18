@[export: 'k_means_clustering_zig']
pub fn k_means_clustering_zig(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 10 { return -1 }
		if input[0] < 2 || input[0] > 8 { return -1 }
		point_count := int(input[0])
		if length != usize(point_count + 1) { return -1 }

		mut points := [8]f32{}
		for index in 0 .. point_count {
			coordinate := input[index + 1]
			if coordinate < -16 || coordinate > 16 || (index > 0 && input[index] >= coordinate) { return -1 }
			points[index] = f32(coordinate)
		}

		mut centers := [2]f32{points[0], points[1]}
		mut old_counts := [2]int{}
		for _ in 0 .. 64 {
			mut sums := [2]f32{}
			mut counts := [2]int{}
			for index in 0 .. point_count {
				point := points[index]
				first_delta := point - centers[0]
				second_delta := centers[1] - point
				first_distance := first_delta * first_delta
				second_distance := second_delta * second_delta
				cluster := if second_distance < first_distance { 1 } else { 0 }
				sums[cluster] = sums[cluster] + point
				counts[cluster]++
			}
			if counts[0] == 0 || counts[1] == 0 { return -1 }
			moved := [2]f32{sums[0] / f32(counts[0]), sums[1] / f32(counts[1])}
			if moved[0] == centers[0] && moved[1] == centers[1] && counts == old_counts {
				code0 := i64(moved[0] * 256.0) + 4097
				code1 := i64(moved[1] * 256.0) + 4097
				if code0 < 1 || code0 > 8193 || code1 < 1 || code1 > 8193 { return -1 }
				return (code0 * 8194 + code1) * 81 + i64(counts[0]) * 9 + i64(counts[1])
			}
			centers = moved
			old_counts = counts
		}
		return -2
	}
}

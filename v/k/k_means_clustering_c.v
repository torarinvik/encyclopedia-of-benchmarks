@[export: 'k_means_clustering_c']
pub fn k_means_clustering_c(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 18 { return -1 }
		if input[0] < 3 || input[0] > 8 { return -1 }
		n := int(input[0])
		if length != usize(1 + 2 * n) { return -1 }

		mut labels := [8]i64{}
		mut has_zero := false
		mut has_one := false
		for index in 0 .. n {
			label := input[index + 1]
			coordinate := input[1 + n + index]
			if label != 0 && label != 1 { return -1 }
			labels[index] = label
			if label == 0 { has_zero = true }
			if label == 1 { has_one = true }
			if coordinate < -16 || coordinate > 16 ||
				(index > 0 && input[n + index] >= coordinate) { return -1 }
		}
		if !has_zero || !has_one { return -1 }

		for _ in 0 .. 64 {
			mut sums := [2]f64{}
			mut counts := [2]int{}
			for index in 0 .. n {
				cluster := int(labels[index])
				sums[cluster] += f64(input[1 + n + index])
				counts[cluster]++
			}
			if counts[0] == 0 || counts[1] == 0 { return -1 }
			centers := [2]f64{sums[0] / f64(counts[0]), sums[1] / f64(counts[1])}

			mut next_labels := [8]i64{}
			mut changed := 0
			for index in 0 .. n {
				point := f64(input[1 + n + index])
				d0 := point - centers[0]
				d1 := point - centers[1]
				if d1 * d1 < d0 * d0 { next_labels[index] = 1 }
				if next_labels[index] != labels[index] { changed++ }
			}
			labels = next_labels
			if changed == 0 {
				code0 := i64(centers[0] * 256.0) + 4097
				code1 := i64(centers[1] * 256.0) + 4097
				if code0 < 1 || code0 > 8193 || code1 < 1 || code1 > 8193 { return -1 }
				return code0 * 8194 + code1
			}
		}
		return -2
	}
}

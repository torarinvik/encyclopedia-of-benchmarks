@[export: 'kmeans_rust']
pub fn kmeans_rust(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 10 { return -1 }
		if input[0] < 2 || input[0] > 8 { return -1 }
		n := int(input[0])
		if length != usize(n + 1) { return -1 }

		mut points := [8]f64{}
		for index in 0 .. n {
			coordinate := input[index + 1]
			if coordinate < -16 || coordinate > 16 || (index > 0 && input[index] >= coordinate) { return -1 }
			points[index] = f64(coordinate)
		}

		mut centers := [2]f64{points[0], points[n / 2]}
		mut labels := [8]i64{}
		for index in 0 .. n {
			d0 := points[index] - centers[0]
			d1 := points[index] - centers[1]
			if d1 * d1 < d0 * d0 { labels[index] = 1 }
		}

		for _ in 0 .. 256 {
			mut sums := [2]f64{}
			mut counts := [2]int{}
			for index in 0 .. n {
				cluster := int(labels[index])
				sums[cluster] += points[index]
				counts[cluster]++
			}
			if counts[0] == 0 || counts[1] == 0 { return -1 }
			centers[0] = sums[0] / f64(counts[0])
			centers[1] = sums[1] / f64(counts[1])

			mut next_labels := [8]i64{}
			mut unchanged := true
			for index in 0 .. n {
				d0 := points[index] - centers[0]
				d1 := points[index] - centers[1]
				if d1 * d1 < d0 * d0 { next_labels[index] = 1 }
				if next_labels[index] != labels[index] { unchanged = false }
			}
			if unchanged {
				mut packed := i64(0)
				for index in 0 .. n { packed |= next_labels[index] << index }
				return packed
			}
			labels = next_labels
		}
		return -2
	}
}

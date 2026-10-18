@[export: 'k_means_rust']
pub fn k_means_rust(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 10 || input[0] != 4 { return -1 }
		max_iter := input[1]
		if max_iter < 1 || max_iter > 16 { return -1 }
		draw0 := input[2]
		draw1 := input[4]
		if input[3] != 0 || input[5] != 0 || draw0 < 0 || draw0 > 9007199254740991 ||
			draw1 < 0 || draw1 > 9007199254740991 || draw0 == draw1 { return -1 }

		mut points := [4]f64{}
		for index in 0 .. 4 {
			coordinate := input[index + 6]
			if coordinate < -16 || coordinate > 16 ||
				(index > 0 && input[index + 5] >= coordinate) { return -1 }
			points[index] = f64(coordinate)
		}
		if input[7] >= 0 || input[8] <= 1 { return -1 }

		mut centers := [2][2]f64{{f64(draw0) / 9007199254740992.0, 0.0},
			{f64(draw1) / 9007199254740992.0, 0.0}}
		mut labels := [4]i64{}
		for _ in 0 .. int(max_iter) {
			mut sums := [2][2]f64{}
			mut counts := [2]int{}
			for index in 0 .. 4 {
				dx0 := points[index] - centers[0][0]
				dy0 := -centers[0][1]
				dx1 := points[index] - centers[1][0]
				dy1 := -centers[1][1]
				distance0 := dx0 * dx0 + dy0 * dy0
				distance1 := dx1 * dx1 + dy1 * dy1
				cluster := if distance1 < distance0 { 1 } else { 0 }
				labels[index] = i64(cluster)
				sums[cluster][0] += points[index]
				sums[cluster][1] += 0.0
				counts[cluster]++
			}
			if counts[0] == 0 || counts[1] == 0 { return -1 }
			for cluster in 0 .. 2 {
				centers[cluster][0] = sums[cluster][0] / f64(counts[cluster])
				centers[cluster][1] = sums[cluster][1] / f64(counts[cluster])
			}
		}

		mut packed := i64(0)
		for index in 0 .. 4 { packed |= labels[index] << index }
		return packed
	}
}

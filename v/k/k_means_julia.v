@[export: 'k_means_julia']
pub fn k_means_julia(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 10 { return -1 }
		if input[0] < 3 || input[0] > 8 { return -1 }
		n := int(input[0])
		if length != usize(n + 1) { return -1 }

		mut points := [8]f64{}
		for index in 0 .. n {
			coordinate := input[index + 1]
			if coordinate < -16 || coordinate > 16 || (index > 0 && input[index] >= coordinate) { return -1 }
			points[index] = f64(coordinate)
		}

		mut centers := [2]f64{points[0], points[n / 2]}
		for _ in 0 .. 64 {
			mut sums := [2]f64{}
			mut counts := [2]int{}
			for index in 0 .. n {
				d0 := points[index] - centers[0]
				d1 := points[index] - centers[1]
				cluster := if d1 * d1 < d0 * d0 { 1 } else { 0 }
				sums[cluster] += points[index]
				counts[cluster]++
			}
			if counts[0] == 0 || counts[1] == 0 { return -1 }
			moved := [2]f64{sums[0] / f64(counts[0]), sums[1] / f64(counts[1])}
			if moved[0] == centers[0] && moved[1] == centers[1] {
				code0 := i64(moved[0] * 256.0) + 4097
				code1 := i64(moved[1] * 256.0) + 4097
				if code0 < 1 || code0 > 8193 || code1 < 1 || code1 > 8193 { return -1 }
				return code0 * 8194 + code1
			}
			centers = moved
		}
		return -2
	}
}

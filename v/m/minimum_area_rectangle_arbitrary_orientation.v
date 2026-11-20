module main

const max_n = 16
const invalid_result = i64(-1)

@[export: 'minimum_area_rectangle_arbitrary_orientation']
pub fn minimum_area_rectangle_arbitrary_orientation(input &i64, length usize) i64 {
	if length < 1 || length > 34 { return invalid_result }
	unsafe {
		if input == nil { return invalid_result }
		n_value := input[0]
		if n_value < 4 || n_value > max_n { return invalid_result }
		n := int(n_value)
		if length != usize(1 + 2*n) { return invalid_result }
		mut xs := []i64{len: n, cap: n}
		mut ys := []i64{len: n, cap: n}
		for i in 0 .. n {
			xs[i] = input[1 + 2*i]
			ys[i] = input[2 + 2*i]
			if xs[i] < -32 || xs[i] > 32 || ys[i] < -32 || ys[i] > 32 { return invalid_result }
			for j in 0 .. i {
				if xs[i] == xs[j] && ys[i] == ys[j] { return invalid_result }
			}
		}

		mut best := i64(-1)
		for i in 0 .. n {
			for j in i + 1 .. n {
				dx1, dy1 := xs[i] - xs[j], ys[i] - ys[j]
				mid_x, mid_y := xs[i] + xs[j], ys[i] + ys[j]
				len1 := dx1*dx1 + dy1*dy1
				for k in 0 .. n {
					for l in k + 1 .. n {
						if k < i || (k == i && l <= j) { continue }
						if k == i || k == j || l == i || l == j { continue }
						if mid_x != xs[k] + xs[l] || mid_y != ys[k] + ys[l] { continue }
						dx2, dy2 := xs[k] - xs[l], ys[k] - ys[l]
						if len1 != dx2*dx2 + dy2*dy2 { continue }
						cross := dx1*dy2 - dy1*dx2
						area2 := cross
						if area2 < 0 { area2 = -area2 }
						if best < 0 || area2 < best { best = area2 }
					}
				}
			}
		}
		if best < 0 { return 0 }
		return best
	}
}

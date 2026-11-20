package minimum_area_rectangle_arbitrary_orientation

import "core:c"

MAX_N :: 16
INVALID_RESULT :: i64(-1)

@(export)
minimum_area_rectangle_arbitrary_orientation :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 34 do return INVALID_RESULT
	n_value := input[0]
	if n_value < 4 || n_value > MAX_N do return INVALID_RESULT
	n := int(n_value)
	if int(length) != 1 + 2*n do return INVALID_RESULT

	xs: [MAX_N]i64
	ys: [MAX_N]i64
	for i in 0..<n {
		xs[i], ys[i] = input[1+2*i], input[2+2*i]
		if xs[i] < -32 || xs[i] > 32 || ys[i] < -32 || ys[i] > 32 do return INVALID_RESULT
		for j in 0..<i {
			if xs[i] == xs[j] && ys[i] == ys[j] do return INVALID_RESULT
		}
	}

	best := i64(-1)
	for i in 0..<n {
		for j in i+1..<n {
			dx1, dy1 := xs[i]-xs[j], ys[i]-ys[j]
			mid_x, mid_y := xs[i]+xs[j], ys[i]+ys[j]
			len1 := dx1*dx1 + dy1*dy1
			for k in 0..<n {
				for l in k+1..<n {
					if k < i || (k == i && l <= j) do continue
					if k == i || k == j || l == i || l == j do continue
					if mid_x != xs[k]+xs[l] || mid_y != ys[k]+ys[l] do continue
					dx2, dy2 := xs[k]-xs[l], ys[k]-ys[l]
					if len1 != dx2*dx2 + dy2*dy2 do continue
					cross := dx1*dy2 - dy1*dx2
					area2 := cross
					if area2 < 0 do area2 = -area2
					if best < 0 || area2 < best do best = area2
				}
			}
		}
	}
	if best < 0 do return 0
	return best
}

module vector2

import math

@[export: 'vector2']
pub fn vector2(values &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if isnil(values) || length != 6 { return -1 }
		for i in 0 .. 6 {
			if values[i] != values[i] || values[i] > 1e100 || values[i] < -1e100 { return -1 }
		}
		if values[0] < 0.0 || values[0] > 10.0 || values[0] != f64(int(values[0])) { return -1 }
		for i in 1 .. 5 {
			if values[i] < -1000.0 || values[i] > 1000.0 { return -1 }
		}
		op := int(values[0])
		ax, ay, bx, by, scalar := values[1], values[2], values[3], values[4], values[5]
		if op == 1 {
			if scalar < 0.0 || scalar > 2000.0 { return -1 }
		} else if op == 6 {
			if bx != 0.0 || by != 0.0 || scalar < -1000.0 || scalar > 1000.0 { return -1 }
		} else if op == 9 {
			if bx != 0.0 || by != 0.0 || scalar < -6.283185307179586 || scalar > 6.283185307179586 { return -1 }
		} else if scalar != 0.0 { return -1 }
		if (op == 2 || op == 3) && (bx != 0.0 || by != 0.0) { return -1 }

		mut result := [2]f64{0.0, 0.0}
		mut result_length := 1
		if op == 0 {
			if ax == bx && ay == by { result[0] = 1.0 }
		} else if op == 1 {
			if math.abs(ax-bx) < scalar && math.abs(ay-by) < scalar { result[0] = 1.0 }
		} else if op == 2 {
			result[0] = math.sqrt(ax*ax + ay*ay)
		} else if op == 3 {
			magnitude := math.sqrt(ax*ax + ay*ay)
			if magnitude == 0.0 { return -1 }
			result_length = 2
			result[0], result[1] = ax/magnitude, ay/magnitude
		} else if op == 4 {
			result_length = 2
			result[0], result[1] = ax+bx, ay+by
		} else if op == 5 {
			result_length = 2
			result[0], result[1] = ax-bx, ay-by
		} else if op == 6 {
			result_length = 2
			result[0], result[1] = ax*scalar, ay*scalar
		} else if op == 7 {
			dx, dy := bx-ax, by-ay
			result[0] = math.sqrt(dx*dx + dy*dy)
		} else if op == 8 {
			result[0] = ax*bx + ay*by
		} else if op == 9 {
			cosine, sine := math.cos(scalar), math.sin(scalar)
			result_length = 2
			result[0], result[1] = cosine*ax-sine*ay, sine*ax+cosine*ay
		} else {
			result[0] = math.atan2(by, bx) - math.atan2(ay, ax)
		}
		if isnil(output) || capacity < usize(result_length) { return -2 }
		for i in 0 .. result_length { output[i] = result[i] }
		return i64(result_length)
	}
}

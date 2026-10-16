module jarvis_scan

const min_coordinate = i64(-10000)
const max_coordinate = i64(10000)

fn orientation(ax i64, ay i64, bx i64, by i64, cx i64, cy i64) i64 {
	return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
}

fn put_i64(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits >> (byte * 8)) }
	}
}

// Return an integer Jarvis-scan hull in counter-clockwise order.
@[export: 'jarvis_scan']
pub fn jarvis_scan(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 { return -1 }
	unsafe {
		count_value := input[0]
		if count_value < 0 || count_value > 64 { return -1 }
		count := int(count_value)
		if int(length) != 1 + 2 * count { return -1 }
		mut x := [64]i64{}
		mut y := [64]i64{}
		for point in 0 .. count {
			x[point] = input[1 + 2 * point]
			y[point] = input[2 + 2 * point]
			if x[point] < min_coordinate || x[point] > max_coordinate ||
				y[point] < min_coordinate || y[point] > max_coordinate { return -1 }
		}
		if count <= 2 { return 0 }
		for first in 0 .. count {
			for second in first + 1 .. count {
				if x[first] == x[second] && y[first] == y[second] { return -1 }
			}
		}
		for first in 0 .. count - 2 {
			for second in first + 1 .. count - 1 {
				for third in second + 1 .. count {
					if orientation(x[first], y[first], x[second], y[second], x[third], y[third]) == 0 { return -1 }
				}
			}
		}

		mut start := 0
		for point in 1 .. count {
			if x[point] < x[start] || (x[point] == x[start] && y[point] < y[start]) { start = point }
		}
		mut hull := [64]int{}
		mut hull_count := 0
		mut current := start
		for {
			if hull_count == count { return -1 }
			hull[hull_count] = current
			hull_count++
			mut candidate := (current + 1) % count
			for point in 0 .. count {
				if orientation(x[current], y[current], x[point], y[point], x[candidate], y[candidate]) > 0 { candidate = point }
			}
			if candidate == start { break }
			current = candidate
		}
		bytes := hull_count * 16
		if unsafe { output == nil } || capacity < usize(bytes) { return -2 }
		for index in 0 .. hull_count {
			put_i64(mut output, index * 16, x[hull[index]])
			put_i64(mut output, index * 16 + 8, y[hull[index]])
		}
		return i64(bytes)
	}
}

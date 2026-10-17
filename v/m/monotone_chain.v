module monotone_chain

const max_point_count = 64
const max_parseable_input_length = 130
const max_coordinate = 1000000

struct Point {
	x i32
	y i32
}

fn point_less(a Point, b Point) bool {
	return a.x < b.x || (a.x == b.x && a.y < b.y)
}

fn cross_product(origin Point, first Point, second Point) i64 {
	dx1 := i64(first.x) - i64(origin.x)
	dy1 := i64(first.y) - i64(origin.y)
	dx2 := i64(second.x) - i64(origin.x)
	dy2 := i64(second.y) - i64(origin.y)
	return dx1 * dy2 - dy1 * dx2
}

fn store_i32_le(output &u8, offset int, value i32) {
	bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'monotone_chain']
pub fn monotone_chain(values &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length < 1 || length > usize(max_parseable_input_length) { return -1 }
		raw_count := values[0]
		if raw_count < 0 || raw_count > max_point_count { return -1 }
		count := int(raw_count)
		if length != usize(1 + 2 * count) { return -1 }

		mut points := [max_point_count]Point{}
		mut scratch := [max_point_count]Point{}
		mut hull := [2 * max_point_count]Point{}
		for index in 0 .. count {
			x := values[1 + 2 * index]
			y := values[2 + 2 * index]
			if x < -max_coordinate || x > max_coordinate || y < -max_coordinate || y > max_coordinate { return -1 }
			points[index] = Point{ x: i32(x), y: i32(y) }
		}

		mut width := 1
		for width < count {
			mut start := 0
			for start < count {
				middle := if start + width < count { start + width } else { count }
				end_index := if middle + width < count { middle + width } else { count }
				mut left := start
				mut right := middle
				mut destination := start
				for left < middle && right < end_index {
					if point_less(points[right], points[left]) {
						scratch[destination] = points[right]
						right++
					} else {
						scratch[destination] = points[left]
						left++
					}
					destination++
				}
				for left < middle {
					scratch[destination] = points[left]
					left++
					destination++
				}
				for right < end_index {
					scratch[destination] = points[right]
					right++
					destination++
				}
				start += 2 * width
			}
			for index in 0 .. count { points[index] = scratch[index] }
			width *= 2
		}

		mut unique_count := 0
		for index in 0 .. count {
			if unique_count == 0 || points[index].x != points[unique_count - 1].x || points[index].y != points[unique_count - 1].y {
				points[unique_count] = points[index]
				unique_count++
			}
		}

		mut hull_count := 0
		if unique_count == 1 {
			hull[hull_count] = points[0]
			hull_count++
		} else if unique_count > 1 {
			for index in 0 .. unique_count {
				for hull_count >= 2 && cross_product(hull[hull_count - 2], hull[hull_count - 1], points[index]) <= 0 {
					hull_count--
				}
				hull[hull_count] = points[index]
				hull_count++
			}
			lower_count := hull_count
			mut index := unique_count - 1
			for index > 0 {
				index--
				for hull_count > lower_count && cross_product(hull[hull_count - 2], hull[hull_count - 1], points[index]) <= 0 {
					hull_count--
				}
				hull[hull_count] = points[index]
				hull_count++
			}
			hull_count--
		}

		byte_count := hull_count * 8
		if output == nil || output_capacity < usize(byte_count) { return -2 }
		for index in 0 .. hull_count {
			store_i32_le(output, 8 * index, hull[index].x)
			store_i32_le(output, 8 * index + 4, hull[index].y)
		}
		return i64(byte_count)
	}
}

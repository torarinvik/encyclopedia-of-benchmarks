package monotone_chain

import "core:c"

MAX_POINT_COUNT :: 64
MAX_PARSEABLE_INPUT_LENGTH :: 130
MAX_COORDINATE :: 1_000_000

Point :: struct { x, y: i64 }

point_less :: proc "contextless" (a, b: Point) -> bool {
	return a.x < b.x || (a.x == b.x && a.y < b.y)
}

cross_product :: proc "contextless" (origin, first, second: Point) -> i64 {
	dx1 := first.x - origin.x
	dy1 := first.y - origin.y
	dx2 := second.x - origin.x
	dy2 := second.y - origin.y
	return dx1 * dy2 - dy1 * dx2
}

store_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8(bits >> u32(byte * 8))
	}
}

@(export)
monotone_chain :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	raw_count := values[0]
	if raw_count < 0 || raw_count > MAX_POINT_COUNT do return -1
	count := int(raw_count)
	if length != c.size_t(1 + 2 * count) do return -1

	points: [MAX_POINT_COUNT]Point
	scratch: [MAX_POINT_COUNT]Point
	hull: [2 * MAX_POINT_COUNT]Point
	for index := 0; index < count; index += 1 {
		x := values[1 + 2 * index]
		y := values[2 + 2 * index]
		if x < -MAX_COORDINATE || x > MAX_COORDINATE ||
			y < -MAX_COORDINATE || y > MAX_COORDINATE do return -1
		points[index].x = x
		points[index].y = y
	}

	width := 1
	for width < count {
		start := 0
		for start < count {
			middle := start + width
			if middle > count do middle = count
			end_index := middle + width
			if end_index > count do end_index = count
			left := start
			right := middle
			destination := start
			for left < middle && right < end_index {
				if point_less(points[right], points[left]) {
					scratch[destination] = points[right]
					right += 1
				} else {
					scratch[destination] = points[left]
					left += 1
				}
				destination += 1
			}
			for left < middle {
				scratch[destination] = points[left]
				left += 1
				destination += 1
			}
			for right < end_index {
				scratch[destination] = points[right]
				right += 1
				destination += 1
			}
			start += 2 * width
		}
		for index := 0; index < count; index += 1 {
			points[index] = scratch[index]
		}
		width *= 2
	}

	unique_count := 0
	for index := 0; index < count; index += 1 {
		if unique_count == 0 || points[index].x != points[unique_count - 1].x ||
			points[index].y != points[unique_count - 1].y {
			points[unique_count] = points[index]
			unique_count += 1
		}
	}

	hull_count := 0
	if unique_count == 1 {
		hull[hull_count] = points[0]
		hull_count += 1
	} else if unique_count > 1 {
		for index := 0; index < unique_count; index += 1 {
			for hull_count >= 2 &&
				cross_product(hull[hull_count - 2], hull[hull_count - 1], points[index]) <= 0 {
				hull_count -= 1
			}
			hull[hull_count] = points[index]
			hull_count += 1
		}
		lower_count := hull_count
		index := unique_count - 1
		for index > 0 {
			index -= 1
			for hull_count > lower_count &&
				cross_product(hull[hull_count - 2], hull[hull_count - 1], points[index]) <= 0 {
				hull_count -= 1
			}
			hull[hull_count] = points[index]
			hull_count += 1
		}
		hull_count -= 1
	}

	byte_count := 8 * hull_count
	if output == nil || output_capacity < c.size_t(byte_count) do return -2
	for index := 0; index < hull_count; index += 1 {
		store_i32_le(output, 8 * index, i32(hull[index].x))
		store_i32_le(output, 8 * index + 4, i32(hull[index].y))
	}
	return i64(byte_count)
}

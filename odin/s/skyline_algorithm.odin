package skyline_algorithm

import "core:c"

MAX_POINTS :: 64
MAX_INPUT_LENGTH :: 130
MAX_OUTPUT_BYTES :: 513

Point :: struct { x: i32, y: i32 }

dominates :: proc(left, right: Point) -> bool {
	return (left.x < right.x && left.y <= right.y) || (left.x <= right.x && left.y < right.y)
}

produce_skyline :: proc(points: ^[MAX_POINTS]Point, start, count: int,
		output: ^[MAX_POINTS]Point) -> int {
	if count == 1 {
		output[0] = points[start]
		return 1
	}
	if count == 2 {
		if dominates(points[start], points[start + 1]) {
			output[0] = points[start]
			return 1
		}
		if dominates(points[start + 1], points[start]) {
			output[0] = points[start + 1]
			return 1
		}
		output[0] = points[start]
		output[1] = points[start + 1]
		return 2
	}

	middle := count / 2
	left: [MAX_POINTS]Point
	right: [MAX_POINTS]Point
	left_count := produce_skyline(points, start, middle, &left)
	right_count := produce_skyline(points, start + middle, count - middle, &right)
	index := 0
	for index + 1 < left_count {
		if left[index].x == left[index + 1].x && left[index].y > left[index + 1].y {
			for move := index; move + 1 < left_count; move += 1 { left[move] = left[move + 1] }
			left_count -= 1
			if index > 0 { index -= 1 }
		} else {
			index += 1
		}
	}
	minimum_y := left[0].y
	for index = 1; index < left_count; index += 1 {
		if minimum_y > left[index].y {
			minimum_y = left[index].y
			if minimum_y == 1 { break }
		}
	}
	index = 0
	for index < right_count {
		if right[index].y >= minimum_y {
			for move := index; move + 1 < right_count; move += 1 { right[move] = right[move + 1] }
			right_count -= 1
		} else {
			index += 1
		}
	}
	for item := 0; item < left_count; item += 1 { output[item] = left[item] }
	for item := 0; item < right_count; item += 1 { output[left_count + item] = right[item] }
	return left_count + right_count
}

@(export)
skyline_algorithm :: proc "c" (input: [^]i64, input_length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_INPUT_LENGTH do return -1
	count_value := input[0]
	if count_value < 1 || count_value > MAX_POINTS do return -1
	count := int(count_value)
	if int(input_length) != 1 + 2 * count do return -1

	points: [MAX_POINTS]Point
	for index := 0; index < count; index += 1 {
		x := input[1 + 2 * index]
		y := input[2 + 2 * index]
		if x < -2147483648 || x > 2147483647 || y < 1 || y > 2147483647 do return -1
		if index > 0 && x <= input[1 + 2 * (index - 1)] do return -1
		points[index] = Point{ i32(x), i32(y) }
	}

	skyline: [MAX_POINTS]Point
	skyline_count := produce_skyline(&points, 0, count, &skyline)
	staged: [MAX_OUTPUT_BYTES]u8
	staged[0] = u8(skyline_count)
	for index := 0; index < skyline_count; index += 1 {
		x_bits := u32(skyline[index].x)
		y_bits := u32(skyline[index].y)
		for byte := 0; byte < 4; byte += 1 {
			staged[1 + 8 * index + byte] = u8(x_bits & 0xff)
			staged[1 + 8 * index + 4 + byte] = u8(y_bits & 0xff)
			x_bits >>= 8
			y_bits >>= 8
		}
	}
	written := 1 + 8 * skyline_count
	if output == nil || output_capacity < c.size_t(written) do return -2
	for index := 0; index < written; index += 1 { output[index] = staged[index] }
	return i64(written)
}

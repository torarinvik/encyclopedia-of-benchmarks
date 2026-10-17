module skyline_algorithm

const max_points = 64
const max_input_length = 130
const max_output_bytes = 513
const i32_min = i64(-2147483648)
const i32_max = i64(2147483647)

struct Point {
	x i32
	y i32
}

fn dominates(left Point, right Point) bool {
	return (left.x < right.x && left.y <= right.y) || (left.x <= right.x && left.y < right.y)
}

fn produce_skyline(points []Point, mut output []Point) int {
	if points.len == 1 {
		output[0] = points[0]
		return 1
	}
	if points.len == 2 {
		if dominates(points[0], points[1]) {
			output[0] = points[0]
			return 1
		}
		if dominates(points[1], points[0]) {
			output[0] = points[1]
			return 1
		}
		output[0] = points[0]
		output[1] = points[1]
		return 2
	}

	middle := points.len / 2
	mut left := []Point{len: max_points}
	mut right := []Point{len: max_points}
	mut left_count := produce_skyline(points[..middle], mut left)
	mut right_count := produce_skyline(points[middle..], mut right)
	mut index := 0
	for index + 1 < left_count {
		if left[index].x == left[index + 1].x && left[index].y > left[index + 1].y {
			for move in index .. left_count - 1 { left[move] = left[move + 1] }
			left_count--
			if index > 0 { index-- }
		} else {
			index++
		}
	}
	mut minimum_y := left[0].y
	for index = 1; index < left_count; index++ {
		if minimum_y > left[index].y {
			minimum_y = left[index].y
			if minimum_y == 1 { break }
		}
	}
	index = 0
	for index < right_count {
		if right[index].y >= minimum_y {
			for move in index .. right_count - 1 { right[move] = right[move + 1] }
			right_count--
		} else {
			index++
		}
	}
	for item in 0 .. left_count { output[item] = left[item] }
	for item in 0 .. right_count { output[left_count + item] = right[item] }
	return left_count + right_count
}

@[export: 'skyline_algorithm']
pub fn skyline_algorithm(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > max_input_length { return -1 }
		count_value := input[0]
		if count_value < 1 || count_value > max_points { return -1 }
		count := int(count_value)
		if input_length != usize(1 + 2 * count) { return -1 }

		mut points := []Point{len: count}
		for index in 0 .. count {
			x_value := input[1 + 2 * index]
			y_value := input[2 + 2 * index]
			if x_value < i32_min || x_value > i32_max || y_value < 1 || y_value > i32_max { return -1 }
			if index > 0 && x_value <= input[1 + 2 * (index - 1)] { return -1 }
			points[index] = Point{x: i32(x_value), y: i32(y_value)}
		}

		mut skyline := []Point{len: max_points}
		skyline_count := produce_skyline(points, mut skyline)
		mut staged := [max_output_bytes]u8{}
		staged[0] = u8(skyline_count)
		for index in 0 .. skyline_count {
			mut x_bits := u32(skyline[index].x)
			mut y_bits := u32(skyline[index].y)
			for byte in 0 .. 4 {
				staged[1 + 8 * index + byte] = u8(x_bits & 255)
				staged[1 + 8 * index + 4 + byte] = u8(y_bits & 255)
				x_bits >>= 8
				y_bits >>= 8
			}
		}
		written := 1 + 8 * skyline_count
		if output == nil || output_capacity < usize(written) { return -2 }
		for index in 0 .. written { output[index] = staged[index] }
		return i64(written)
	}
}

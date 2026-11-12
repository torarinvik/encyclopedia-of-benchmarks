module circle_line_intersection_count

const max_q = 32
const max_output_bytes = 8 * max_q

fn write_i64(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'circle_line_intersection_count']
pub fn circle_line_intersection_count(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length < 4 || length > 101 { return -1 }
	unsafe {
		center_x, center_y, radius, query_value := input[0], input[1], input[2], input[3]
		if center_x < -1000 || center_x > 1000 || center_y < -1000 || center_y > 1000 ||
			radius < 0 || radius > 1000 || query_value < 0 || query_value > max_q { return -1 }
		query_count := int(query_value)
		if int(length) != 4 + 3 * query_count { return -1 }
		mut a_values := [max_q]i64{}
		mut b_values := [max_q]i64{}
		mut c_values := [max_q]i64{}
		for query in 0 .. query_count {
			a, b, c_value := input[4 + 3 * query], input[5 + 3 * query], input[6 + 3 * query]
			if a < -100 || a > 100 || b < -100 || b > 100 || (a == 0 && b == 0) ||
				c_value < -200000 || c_value > 200000 { return -1 }
			a_values[query], b_values[query], c_values[query] = a, b, c_value
		}
		needed := 8 * query_count
		if needed > 0 && (output == nil || capacity < usize(needed)) { return -2 }
		mut staged := [max_output_bytes]u8{}
		for query in 0 .. query_count {
			a, b, c_value := a_values[query], b_values[query], c_values[query]
			offset := a * center_x + b * center_y + c_value
			normal_squared := a * a + b * b
			discriminant := radius * radius * normal_squared - offset * offset
			mut count := i64(0)
			if discriminant > 0 { count = 2 } else if discriminant == 0 { count = 1 }
			write_i64(mut staged[0], 8 * query, count)
		}
		for byte in 0 .. needed { output[byte] = staged[byte] }
		return i64(needed)
	}
}

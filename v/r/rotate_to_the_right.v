module rotate_to_the_right

const max_n = 64
const max_parseable_input_length = max_n + 4
const max_output_bytes = max_n * 8
const max_places = i64(1000000)
const i32_min_value = i64(-2147483648)
const i32_max_value = i64(2147483647)

@[export: 'rotate_to_the_right']
pub fn rotate_to_the_right(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 3 || length > max_parseable_input_length { return -1 }
	unsafe {
		if input == nil { return -1 }
		n_value := input[0]
		places := input[1]
		if n_value < 1 || n_value > i64(max_n) || places < -max_places || places > max_places { return -1 }
		n := int(n_value)
		if length != usize(n + 2) { return -1 }
		for index in 0 .. n {
			value := input[2 + index]
			if value < i32_min_value || value > i32_max_value { return -1 }
		}

		remainder := places % n_value
		shift := int(remainder)
		if remainder < 0 { shift = int(remainder + n_value) }
		output_bytes := n * 8
		if output == nil || output_capacity < usize(output_bytes) { return -2 }

		mut encoded := []u8{len: max_output_bytes}
		for index in 0 .. n {
			source := (index + n - shift) % n
			mut bits := u64(input[2 + source])
			for byte in 0 .. 8 {
				encoded[index * 8 + byte] = u8(bits & 255)
				bits >>= 8
			}
		}
		for index in 0 .. output_bytes { output[index] = encoded[index] }
		return i64(output_bytes)
	}
}

const max_requests = 64
const max_output_values = 65

fn sort_ascending(mut values [64]i32, count int) {
	for i := 1; i < count; i++ {
		value := values[i]
		mut position := i
		for position > 0 && values[position - 1] > value {
			values[position] = values[position - 1]
			position--
		}
		values[position] = value
	}
}

fn put_i32_le(mut output &u8, offset int, value i32) {
	mut bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'scan_scheduling']
pub fn scan_scheduling(input &i32, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if isnil(input) || length < 4 || length > 68 { return -1 }
		disk_size, head, direction, request_count := input[0], input[1], input[2], input[3]
		if disk_size < 1 || disk_size > 256 || head < 0 || head >= disk_size ||
			(direction != 0 && direction != 1) || request_count < 0 || request_count > max_requests ||
			length != usize(4 + request_count) { return -1 }

		mut left := [64]i32{}
		mut right := [64]i32{}
		mut left_count := 0
		mut right_count := 0
		for i := 0; i < int(request_count); i++ {
			request := input[4 + i]
			if request < 0 || request >= disk_size { return -1 }
			if request < head {
				left[left_count] = request
				left_count++
			} else {
				right[right_count] = request
				right_count++
			}
		}
		sort_ascending(mut left, left_count)
		sort_ascending(mut right, right_count)

		mut ordered := [65]i32{}
		mut count := 0
		if request_count > 0 {
			if direction == 1 {
				for i := 0; i < right_count; i++ { ordered[count] = right[i]; count++ }
				ordered[count] = disk_size - 1
				count++
				for i := left_count; i > 0; i-- { ordered[count] = left[i - 1]; count++ }
			} else {
				for i := left_count; i > 0; i-- { ordered[count] = left[i - 1]; count++ }
				ordered[count] = 0
				count++
				for i := 0; i < right_count; i++ { ordered[count] = right[i]; count++ }
			}
		}
		bytes := count * 4
		if isnil(output) || capacity < usize(bytes) { return -2 }
		for i := 0; i < count; i++ { put_i32_le(mut output, i * 4, ordered[i]) }
		return i64(bytes)
	}
}

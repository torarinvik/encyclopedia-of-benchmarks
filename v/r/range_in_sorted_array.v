module range_in_sorted_array

const max_n = 512
const int32_min_value = -2147483648
const int32_max_value = 2147483647

fn find_bound(values &i64, offset int, n int, key i64, find_left bool) i32 {
	mut left := 0
	mut right := n - 1
	for left <= right {
		mid := left + (right - left) / 2
		if unsafe { values[offset + mid] } > key { right = mid - 1 }
		else if unsafe { values[offset + mid] } < key { left = mid + 1 }
		else if find_left {
			if mid == 0 || unsafe { values[offset + mid - 1] } != key { return i32(mid) }
			right = mid - 1
		} else {
			if mid == n - 1 || unsafe { values[offset + mid + 1] } != key { return i32(mid) }
			left = mid + 1
		}
	}
	return -1
}

fn put_i32_le(output &u8, offset int, value i32) {
	bits := u32(value)
	unsafe {
		for byte in 0 .. 4 {
			output[offset + byte] = u8((bits >> u32(8 * byte)) & 255)
		}
	}
}

@[export: 'range_in_sorted_array']
pub fn range_in_sorted_array(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 2 { return -1 }
	unsafe {
		if input == nil { return -1 }
		if input[0] < 0 || input[0] > max_n || length != usize(input[0] + 2) { return -1 }
		n := int(input[0])
		key := input[n + 1]
		if key < int32_min_value || key > int32_max_value { return -1 }
		for index in 0 .. n {
			value := input[index + 1]
			if value < int32_min_value || value > int32_max_value { return -1 }
			if index > 0 && input[index] > value { return -1 }
		}
		first := find_bound(input, 1, n, key, true)
		last := find_bound(input, 1, n, key, false)
		if output == nil || output_capacity < 8 { return -2 }
		put_i32_le(output, 0, first)
		put_i32_le(output, 4, last)
		return 8
	}
}

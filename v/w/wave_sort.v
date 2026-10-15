module wave_sort

const max_array_length = 4096

fn sift_down(mut values &i64, root_start int, end_value int) {
	mut root := root_start
	for root < end_value / 2 {
		mut child := root * 2 + 1
		if child + 1 < end_value && unsafe { values[child] < values[child + 1] } { child++ }
		if unsafe { values[root] >= values[child] } { break }
		unsafe {
			temporary := values[root]
			values[root] = values[child]
			values[child] = temporary
		}
		root = child
	}
}

fn heap_sort(mut values &i64, length int) {
	mut start := length / 2
	for start > 0 {
		start--
		sift_down(mut values, start, length)
	}
	mut ending := length
	for ending > 1 {
		ending--
		unsafe {
			temporary := values[0]
			values[0] = values[ending]
			values[ending] = temporary
		}
		sift_down(mut values, 0, ending)
	}
}

fn store_i32_le(output &u8, offset int, value i64) {
	bits := u32(i32(value))
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'wave_sort']
pub fn wave_sort(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > max_array_length { return -1 }
	mut values := [max_array_length]i64{init: 0}
	for index in 0 .. length {
		value := unsafe { input[index] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		values[index] = value
	}
	heap_sort(mut values[0], int(length))
	for index := 0; index + 1 < int(length); index += 2 {
		temporary := values[index]
		values[index] = values[index + 1]
		values[index + 1] = temporary
	}
	bytes := length * 4
	if output_capacity < bytes { return -2 }
	for out_index in 0 .. length { store_i32_le(output, int(out_index * 4), values[out_index]) }
	return i64(length)
}

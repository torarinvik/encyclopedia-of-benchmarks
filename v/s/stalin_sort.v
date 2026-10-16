module stalin_sort

fn store_i32_le(mut output &u8, offset int, value i64) {
	bits := u32(i32(value))
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

// Keep each value that is not smaller than the last retained value.
@[export: 'stalin_sort']
pub fn stalin_sort(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length > 128 || (length != 0 && unsafe { values == nil }) { return -1 }
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < -2147483648 || value > 2147483647 { return -1 }
	}
	mut kept := 0
	mut last := i64(0)
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if kept == 0 || value >= last {
			kept++
			last = value
		}
	}
	output_bytes := kept * 4
	if unsafe { output == nil } || output_capacity < output_bytes { return -2 }
	mut output_index := 0
	last = 0
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if output_index == 0 || value >= last {
			store_i32_le(mut output, output_index * 4, value)
			output_index++
			last = value
		}
	}
	return output_bytes
}

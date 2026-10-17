module merge_sort_no_extra_space

const max_length = 256

fn read_i32_le(buffer &u8, index int) i32 {
	unsafe {
		offset := index * 4
		bits := u32(buffer[offset]) | (u32(buffer[offset + 1]) << 8) | (u32(buffer[offset + 2]) << 16) | (u32(buffer[offset + 3]) << 24)
		return i32(bits)
	}
}

fn write_i32_le(mut buffer &u8, index int, value i32) {
	unsafe {
		mut bits := u32(value)
		offset := index * 4
		for byte in 0 .. 4 {
			buffer[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

fn merge(mut buffer &u8, start int, middle int, finish int, max_element i32) {
	mut i := start
	mut j := middle + 1
	mut k := start
	for i <= middle && j <= finish {
		left := read_i32_le(buffer, i) % max_element
		right := read_i32_le(buffer, j) % max_element
		current := read_i32_le(buffer, k)
		if left <= right {
			write_i32_le(mut buffer, k, current + left * max_element)
			i++
		} else {
			write_i32_le(mut buffer, k, current + right * max_element)
			j++
		}
		k++
	}
	for i <= middle {
		current := read_i32_le(buffer, k)
		next := read_i32_le(buffer, i) % max_element
		write_i32_le(mut buffer, k, current + next * max_element)
		i++
		k++
	}
	for j <= finish {
		current := read_i32_le(buffer, k)
		next := read_i32_le(buffer, j) % max_element
		write_i32_le(mut buffer, k, current + next * max_element)
		j++
		k++
	}
	for index in start .. finish + 1 {
		write_i32_le(mut buffer, index, read_i32_le(buffer, index) / max_element)
	}
}

fn merge_sort(mut buffer &u8, start int, finish int, max_element i32) {
	if start >= finish { return }
	middle := start + (finish - start) / 2
	merge_sort(mut buffer, start, middle, max_element)
	merge_sort(mut buffer, middle + 1, finish, max_element)
	merge(mut buffer, start, middle, finish, max_element)
}

@[export: 'merge_sort_no_extra_space']
pub fn merge_sort_no_extra_space(values &i32, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || length > usize(max_length) { return -1 }
		mut max_value := i32(0)
		for index in 0 .. int(length) {
			if values[index] < 0 || values[index] > 32767 { return -1 }
			if values[index] > max_value { max_value = values[index] }
		}
		output_bytes := int(length) * 4
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for index in 0 .. int(length) { write_i32_le(mut output, index, values[index]) }
		if length > 1 { merge_sort(mut output, 0, int(length) - 1, max_value + 1) }
		return i64(output_bytes)
	}
}

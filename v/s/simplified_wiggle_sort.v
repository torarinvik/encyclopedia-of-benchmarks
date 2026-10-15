module simplified_wiggle_sort

const max_array_length = 4096

fn store_i32_le(output &u8, offset int, value i64) {
	bits := u32(i32(value))
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'simplified_wiggle_sort']
pub fn simplified_wiggle_sort(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > max_array_length { return -1 }
	if output_capacity < length * 4 { return -2 }
	mut values := [max_array_length]i64{init: 0}
	mut ordered := [max_array_length]i64{init: 0}
	for i in 0 .. length {
		value := unsafe { input[i] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		values[i] = value
	}
	if length == 0 { return 0 }

	mut low := 0
	mut high := int(length) - 1
	target := int(length) / 2
	for low < high {
		mut left := low
		mut right := high
		pivot := values[(left + right + 1) / 2]
		for left <= right {
			for left <= right && values[left] < pivot { left++ }
			for left <= right && values[right] > pivot { right-- }
			if left <= right {
				temporary := values[left]
				values[left] = values[right]
				values[right] = temporary
				left++
				right--
			}
		}
		if target <= right { high = right }
		else if target >= left { low = left }
		else { break }
	}
	median := values[target]
	mut smaller := 0
	mut greater := int(length) - 1 - (int(length) % 2)
	for i in 0 .. length {
		if values[i] > median {
			ordered[greater] = values[i]
			greater -= 2
		} else if smaller < int(length) {
			ordered[smaller] = values[i]
			smaller += 2
		} else {
			ordered[greater] = values[i]
			greater -= 2
		}
	}
	for i in 0 .. length { store_i32_le(output, int(i * 4), ordered[i]) }
	return i64(length)
}

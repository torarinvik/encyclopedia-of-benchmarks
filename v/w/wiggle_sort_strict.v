module wiggle_sort_strict

const max_array_length = 4096

fn store_i32_le(output &u8, offset int, value i64) {
	bits := u32(i32(value))
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'wiggle_sort_strict']
pub fn wiggle_sort_strict(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > max_array_length { return -1 }
	if output_capacity < length * 4 { return -2 }
	mut values := [max_array_length]i64{init: 0}
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
	mut median_count := 0
	mut smallest_value := values[0]
	for index in 0 .. length {
		if values[index] == median { median_count++ }
		if values[index] < smallest_value { smallest_value = values[index] }
	}
	maximum_medians := (int(length) + 1) / 2
	if median_count > maximum_medians || (int(length) % 2 == 1 && median_count == maximum_medians && smallest_value != median) { return -1 }

	mut i := 0
	mut j := 0
	mut k := int(length) - 1
	modulus := int(length) + 1 - (int(length) % 2)
	for j <= k {
		mapped_j := (2 * j + 1) % modulus
		if values[mapped_j] > median {
			mapped_i := (2 * i + 1) % modulus
			temporary := values[mapped_j]
			values[mapped_j] = values[mapped_i]
			values[mapped_i] = temporary
			i++
			j++
		} else if values[mapped_j] < median {
			mapped_k := (2 * k + 1) % modulus
			temporary := values[mapped_j]
			values[mapped_j] = values[mapped_k]
			values[mapped_k] = temporary
			k--
		} else {
			j++
		}
	}
	for output_index in 0 .. length { store_i32_le(output, int(output_index * 4), values[output_index]) }
	return i64(length)
}

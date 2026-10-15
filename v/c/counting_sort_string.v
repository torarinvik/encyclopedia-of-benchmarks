module counting_sort_string

const max_text_length = i64(4095)

@[export: 'counting_sort_string']
pub fn counting_sort_string(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length < 1 || length > 4096 { return -1 }
	unsafe {
		count := values[0]
		if count < 0 || count > max_text_length || length != usize(count + 1) { return -1 }

		mut frequencies := [256]i64{init: 0}
		for index in 0 .. int(count) {
			value := values[index + 1]
			if value < 33 || value > 126 { return -1 }
			frequencies[int(value)]++
		}
		if output == nil || output_capacity < usize(count) { return -2 }

		for value in 1 .. 256 { frequencies[value] += frequencies[value - 1] }
		for index := int(count); index > 0; index-- {
			value := int(values[index])
			frequencies[value]--
			output[int(frequencies[value])] = u8(value)
		}
		return count
	}
}

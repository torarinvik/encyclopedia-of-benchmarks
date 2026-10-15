module circular_convolution

@[export: 'circular_convolution']
pub fn circular_convolution(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 4 || unsafe { values == nil } { return -1 }
	unsafe {
		raw_a_length := values[0]
		raw_b_length := values[1]
		if raw_a_length < 1 || raw_a_length > 8 || raw_b_length < 1 || raw_b_length > 8 { return -1 }
		a_length := int(raw_a_length)
		b_length := int(raw_b_length)
		if length != usize(2 + a_length + b_length) { return -1 }
		for index in 0 .. a_length + b_length {
			if values[2 + index] < -2 || values[2 + index] > 2 { return -1 }
		}
		n := if a_length > b_length { a_length } else { b_length }
		if unsafe { output == nil } || output_capacity < usize(n) { return -2 }
		for k in 0 .. n {
			mut sum := i64(0)
			for i in 0 .. n {
				b_index := (k + n - i) % n
				a_value := if i < a_length { values[2 + i] } else { i64(0) }
				b_value := if b_index < b_length { values[2 + a_length + b_index] } else { i64(0) }
				sum += a_value * b_value
			}
			output[k] = u8(if sum < 0 { sum + 256 } else { sum })
		}
		return i64(n)
	}
}

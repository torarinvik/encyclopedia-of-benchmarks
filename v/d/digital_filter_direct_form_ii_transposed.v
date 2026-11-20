module digital_filter_direct_form_ii_transposed

@[export: 'digital_filter_direct_form_ii_transposed']
pub fn digital_filter_direct_form_ii_transposed(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > 45 { return -1 }
	unsafe {
		count_word := input[0]
		order_word := input[1]
		if count_word < 0 || count_word > 32 || order_word < 0 || order_word > 4 { return -1 }
		count := int(count_word)
		order := int(order_word)
		if length != usize(count + 2 * order + 4) { return -1 }
		a_start := 2
		b_start := order + 3
		x_start := 2 * order + 4
		if input[a_start] != 1 { return -1 }
		for index in 1 .. order + 1 { if input[a_start + index] < -1 || input[a_start + index] > 1 { return -1 } }
		for index in 0 .. order + 1 { if input[b_start + index] < -1 || input[b_start + index] > 1 { return -1 } }
		for index in 0 .. count { if input[x_start + index] < -16 || input[x_start + index] > 16 { return -1 } }
		bytes := count * 8
		if bytes > 0 && (output == nil || capacity < usize(bytes)) { return -2 }
		if count == 0 { return 0 }
		mut state := [4]i64{}
		for sample_index in 0 .. count {
			sample := input[x_start + sample_index]
			mut value := input[b_start] * sample
			if order > 0 { value += state[0] }
			for stage in 0 .. order {
				next_state := if stage + 1 < order { state[stage + 1] } else { i64(0) }
				state[stage] = next_state + input[b_start + stage + 1] * sample - input[a_start + stage + 1] * value
			}
			bits := u64(value)
			for byte_index in 0 .. 8 { output[sample_index * 8 + byte_index] = u8((bits >> (byte_index * 8)) & 255) }
		}
		return i64(bytes)
	}
}

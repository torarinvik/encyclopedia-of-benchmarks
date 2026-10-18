fn exact_integer(value f64, minimum i64, maximum i64) bool {
	if !value.is_finite() || value < f64(minimum) || value > f64(maximum) { return false }
	return f64(i64(value)) == value
}

@[export: 'shuffle']
pub fn shuffle(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > 513 { return -1 }
		if !exact_integer(input[0], 0, 256) { return -1 }
		count := int(input[0])
		mut offset_count := 0
		if count > 0 { offset_count = count - 1 }
		if input_length != usize(1 + count + offset_count) { return -1 }

		mut items := [256]i32{}
		for index in 0 .. count {
			value := input[index + 1]
			if !exact_integer(value, -2147483648, 2147483647) { return -1 }
			items[index] = i32(value)
		}
		mut offsets := [256]int{}
		for index in 0 .. offset_count {
			value := input[1 + count + index]
			if !exact_integer(value, 0, i64(count - 1 - index)) { return -1 }
			offsets[index] = int(value)
		}
		for index in 0 .. offset_count {
			other := index + offsets[index]
			temporary := items[index]
			items[index] = items[other]
			items[other] = temporary
		}

		if output == nil || capacity < usize(count) { return -2 }
		for index in 0 .. count { output[index] = f64(items[index]) }
		return i64(count)
	}
}

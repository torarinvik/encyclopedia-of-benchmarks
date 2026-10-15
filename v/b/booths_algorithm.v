module booths_algorithm

@[export: 'booths_algorithm']
pub fn booths_algorithm(values &i64, length usize, mut output &u8, capacity usize) i64 {
	if length == 0 || length > 256 || unsafe { values == nil } { return -1 }
	unsafe {
		for index in 0 .. int(length) {
			if values[index] < 0 || values[index] > 127 { return -1 }
		}
		if output == nil || capacity < length { return -2 }

		mut failure := [512]i64{init: -1}
		mut start := 0
		for j in 1 .. int(2 * length) {
			current := values[j % int(length)]
			mut matched := failure[j - start - 1]
			for matched != -1 && current != values[(start + int(matched) + 1) % int(length)] {
				if current < values[(start + int(matched) + 1) % int(length)] {
					start = j - int(matched) - 1
				}
				matched = failure[int(matched)]
			}
			if matched == -1 && current != values[start % int(length)] {
				if current < values[start % int(length)] { start = j }
				failure[j - start] = -1
			} else {
				failure[j - start] = matched + 1
			}
		}

		for index in 0 .. int(length) {
			output[index] = u8(values[(start + index) % int(length)])
		}
		return i64(length)
	}
}

module letter_combinations_of_phone_number

fn letter_count(digit i64) usize {
	if digit == 7 || digit == 9 { return 4 }
	return 3
}

fn letter_base(digit i64) u8 {
	match digit {
		2 { return u8(`a`) }
		3 { return u8(`d`) }
		4 { return u8(`g`) }
		5 { return u8(`j`) }
		6 { return u8(`m`) }
		7 { return u8(`p`) }
		8 { return u8(`t`) }
		else { return u8(`w`) }
	}
}

fn expand(digits &i64, length usize, index usize, output &u8,
		output_offset usize, combination_count usize) {
	if index == length { return }
	alternatives := letter_count(unsafe { digits[index] })
	block_count := combination_count / alternatives
	base := letter_base(unsafe { digits[index] })
	for letter in 0 .. alternatives {
		branch_offset := output_offset + letter * block_count * length
		for row in 0 .. block_count {
			unsafe { output[branch_offset + row * length + index] = base + u8(letter) }
		}
		expand(digits, length, index + 1, output, branch_offset, block_count)
	}
}

// Recursively enumerate 2–9 keypad letters into fixed-width concatenated slots.
@[export: 'letter_combinations_of_phone_number']
pub fn letter_combinations_of_phone_number(digits &i64, length usize, output &u8,
		output_capacity usize) i64 {
	if length == 0 { return 0 }
	if length > 6 { return -1 }
	mut count := usize(1)
	for index in 0 .. length {
		digit := unsafe { digits[index] }
		if digit < 2 || digit > 9 { return -1 }
		count *= letter_count(digit)
	}
	required := count * length
	if output_capacity < required { return -2 }
	expand(digits, length, 0, output, 0, count)
	return i64(count)
}

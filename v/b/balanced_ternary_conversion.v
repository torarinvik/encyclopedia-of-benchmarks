module balanced_ternary_conversion

const max_output_bytes = 41

@[export: 'balanced_ternary_conversion']
pub fn balanced_ternary_conversion(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length != 1 || unsafe { input == nil } { return -1 }
	unsafe {
		mut reversed := [max_output_bytes]u8{}
		mut digit_count := 0
		mut value := input[0]
		if value == 0 {
			reversed[digit_count] = u8(48)
			digit_count++
		}
		for value != 0 {
			mut quotient := value / 3
			remainder := value % 3
			mut digit := u8(49)
			if remainder == 2 {
				digit = u8(90)
				quotient++
			} else if remainder == -2 {
				digit = u8(49)
				quotient--
			} else if remainder == -1 {
				digit = u8(90)
			} else if remainder == 0 {
				digit = u8(48)
			}
			reversed[digit_count] = digit
			digit_count++
			value = quotient
		}
		if output == nil || capacity < usize(digit_count) { return -2 }
		for index in 0 .. digit_count {
			output[index] = reversed[digit_count - index - 1]
		}
		return i64(digit_count)
	}
}

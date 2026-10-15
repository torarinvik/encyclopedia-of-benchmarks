module digit_separation

// Separate signed decimal digits; direction 0 is reverse and 1 is forward.
@[export: 'digit_separation']
pub fn digit_separation(input &i64, input_length usize, mut output &u8,
		output_capacity usize) i64 {
	if input_length != 2 || (input[1] != 0 && input[1] != 1) { return -1 }
	mut remaining := input[0]
	mut digits := [20]u8{}
	mut count := 0
	if remaining == 0 { digits[0] = 0; count = 1 }
	for remaining != 0 {
		remainder := remaining % 10
		digits[count] = u8(if remainder < 0 { -remainder } else { remainder })
		count++
		remaining /= 10
	}
	if output_capacity < usize(count) { return -2 }
	for index in 0 .. count {
		source := index
		if input[1] == 1 { source = count - index - 1 }
		unsafe { output[index] = digits[source] }
	}
	return i64(count)
}

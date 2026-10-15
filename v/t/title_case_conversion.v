module title_case_conversion

const max_length = 256

// Apply the pinned JavaScript title-case behavior to bounded ASCII words.
@[export: 'title_case_conversion']
pub fn title_case_conversion(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length == 0 || length > max_length + 1 { return -1 }
	declared := unsafe { input[0] }
	if declared < 0 || declared > max_length || length != usize(declared) + 1 { return -1 }
	for index in 0 .. declared {
		value := unsafe { input[index + 1] }
		letter := (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
		if !letter && value != 32 { return -1 }
		if value == 32 && (index == 0 || index + 1 == declared || unsafe { input[index] } == 32) { return -1 }
	}
	if output_capacity < usize(declared) + 1 { return -2 }
	mut at_word_start := true
	for index in 0 .. declared {
		mut value := unsafe { input[index + 1] }
		if value == 32 { at_word_start = true }
		else if at_word_start {
			if value >= 97 && value <= 122 { value -= 32 }
			at_word_start = false
		} else if value >= 65 && value <= 90 { value += 32 }
		unsafe { output[index] = u8(value) }
	}
	unsafe { output[declared] = 0 }
	return declared
}

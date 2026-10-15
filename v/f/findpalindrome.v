module findpalindrome

const max_length = 4096

fn is_punctuation(value i64) bool {
	return (value >= 33 && value <= 47) || (value >= 58 && value <= 64) ||
		(value >= 91 && value <= 96) || (value >= 123 && value <= 126)
}

fn lower_ascii(value i64) i64 {
	if value >= 65 && value <= 90 { return value + 32 }
	return value
}

@[export: 'findpalindrome']
pub fn findpalindrome(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > max_length { return -1 }
	if length > 0 && unsafe { input == nil } { return -1 }
	for index in 0 .. length {
		value := unsafe { input[index] }
		if value < 32 || value > 126 { return -1 }
	}

	mut written := usize(0)
	mut found := false
	mut segment := usize(0)
	for ending in 0 .. length + 1 {
		if ending < length && unsafe { input[ending] != 32 } { continue }
		mut token_length := usize(0)
		for index in segment .. ending {
			if !is_punctuation(unsafe { input[index] }) { token_length++ }
		}
		mut left := segment
		mut right := ending
		mut matched := true
		for left < right {
			for left < right {
				if !is_punctuation(unsafe { input[left] }) { break }
				left++
			}
			for left < right {
				if !is_punctuation(unsafe { input[right - 1] }) { break }
				right--
			}
			if left < right {
				if lower_ascii(unsafe { input[left] }) != lower_ascii(unsafe { input[right - 1] }) {
					matched = false
					break
				}
				left++
				right--
			}
		}
		if token_length > 1 && matched {
			mut needed := token_length
			if found { needed++ }
			if written + needed > output_capacity || unsafe { output == nil } { return -2 }
			unsafe {
				if found {
					output[written] = 0
					written++
				}
			for index in segment .. ending {
					value := input[index]
					if !is_punctuation(value) {
						output[written] = u8(value)
						written++
					}
				}
			}
			found = true
		}
		segment = ending + 1
	}
	return i64(written)
}

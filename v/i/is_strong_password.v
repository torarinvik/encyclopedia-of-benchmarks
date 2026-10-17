module is_strong_password

const max_input = 258

@[export: 'is_strong_password']
pub fn is_strong_password(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input { return -1 }
	unsafe {
		minimum_length, text_length_value := input[0], input[1]
		if minimum_length < 0 || minimum_length > 256 || text_length_value < 0 || text_length_value > 256 { return -1 }
		text_length := int(text_length_value)
		if length != usize(text_length + 2) { return -1 }

		mut has_uppercase, mut has_lowercase, mut has_digit, mut has_punctuation := false, false, false, false
		for index in 0 .. text_length {
			value := input[index + 2]
			if value < 0 || value > 127 { return -1 }
			if value >= 65 && value <= 90 { has_uppercase = true }
			if value >= 97 && value <= 122 { has_lowercase = true }
			if value >= 48 && value <= 57 { has_digit = true }
			if (value >= 33 && value <= 47) || (value >= 58 && value <= 64) ||
				(value >= 91 && value <= 96) || (value >= 123 && value <= 126) { has_punctuation = true }
		}

		if text_length_value < minimum_length { return 0 }
		if has_uppercase && has_lowercase && has_digit && has_punctuation { return 1 }
		return 0
	}
}

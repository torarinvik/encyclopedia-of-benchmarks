module check_vowels

const max_length = 4096

// Return whether any lowercase ASCII vowel appears in the input.
@[export: 'check_vowels']
pub fn check_vowels(values &i64, length usize) i64 {
	if length > max_length { return -1 }
	if length == 0 { return 0 }
	unsafe {
		data := values[..length]
		for value in data {
			if value < 97 || value > 122 { return -1 }
		}
		for value in data {
			if value == 97 || value == 101 || value == 105 || value == 111 || value == 117 { return 1 }
		}
		return 0
	}
}

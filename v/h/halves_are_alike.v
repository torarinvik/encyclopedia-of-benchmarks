module halves_are_alike

// Compare the vowel counts in two equal ASCII-letter halves.
@[export: 'halves_are_alike']
pub fn halves_are_alike(letters &i64, length usize) i64 {
	if length > 256 || length % 2 != 0 { return -1 }
	if length == 0 { return 1 }
	unsafe {
		half := int(length / 2)
		mut first := 0
		mut second := 0
		for index in 0 .. length {
			value := letters[index]
			if !((value >= 97 && value <= 122) || (value >= 65 && value <= 90)) { return -1 }
			vowel := value == 97 || value == 101 || value == 105 || value == 111 || value == 117 ||
				value == 65 || value == 69 || value == 73 || value == 79 || value == 85
			if vowel {
				if index < half { first++ }
				else { second++ }
			}
		}
		return if first == second { 1 } else { 0 }
	}
}

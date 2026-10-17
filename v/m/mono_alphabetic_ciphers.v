module mono_alphabetic_ciphers

const max_parseable_input_length = 157
const fnv_offset_basis = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)
const mask_63 = u64(0x7fffffffffffffff)

@[export: 'mono_alphabetic_ciphers']
pub fn mono_alphabetic_ciphers(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_parseable_input_length) { return -1 }
		operation := input[0]
		raw_text_length := input[1]
		if (operation != 0 && operation != 1) || raw_text_length < 0 || raw_text_length > 128 { return -1 }
		text_length := int(raw_text_length)
		if length != usize(28 + text_length) { return -1 }

		mut seen := [26]bool{}
		mut inverse := [26]int{}
		for i in 0 .. 26 {
			value := input[2 + i]
			if value < 65 || value > 90 { return -1 }
			index := int(value - 65)
			if seen[index] { return -1 }
			seen[index] = true
			inverse[index] = i
		}
		for i in 0 .. text_length {
			if input[28 + i] < 32 || input[28 + i] > 126 { return -1 }
		}

		mut hash := fnv_offset_basis
		length_word := u64(text_length)
		for byte in 0 .. 8 {
			hash = (hash ^ ((length_word >> (byte * 8)) & 255)) * fnv_prime
		}
		for i in 0 .. text_length {
			value := input[28 + i]
			mut mapped := value
			if (value >= 65 && value <= 90) || (value >= 97 && value <= 122) {
				lower := value >= 97 && value <= 122
				letter := int(value - 65)
				if lower { letter = int(value - 97) }
				position := if operation == 0 { inverse[letter] } else { letter }
				target := if operation == 0 { i64(65 + position) } else { input[2 + position] }
				if lower { mapped = target + 32 } else { mapped = target }
			}
			hash = (hash ^ u64(mapped)) * fnv_prime
		}
		return i64(hash & mask_63)
	}
}

module mono_alphabetic_cipher

const max_parseable_input_length = 183
const fnv_offset_basis = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)
const mask_63 = u64(0x7fffffffffffffff)

@[export: 'mono_alphabetic_cipher']
pub fn mono_alphabetic_cipher(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_parseable_input_length) { return -1 }
		operation := input[0]
		raw_text_length := input[1]
		if (operation != 0 && operation != 1) || raw_text_length < 0 || raw_text_length > 128 { return -1 }
		text_length := int(raw_text_length)
		if length != usize(54 + text_length) { return -1 }

		mut key_seen := [26]bool{}
		mut alphabet_seen := [26]bool{}
		mut key_inverse := [26]int{}
		mut alphabet_inverse := [26]int{}
		for i in 0 .. 26 {
			key_value := input[2 + i]
			alphabet_value := input[28 + i]
			if key_value < 65 || key_value > 90 || alphabet_value < 65 || alphabet_value > 90 { return -1 }
			key_index := int(key_value - 65)
			alphabet_index := int(alphabet_value - 65)
			if key_seen[key_index] || alphabet_seen[alphabet_index] { return -1 }
			key_seen[key_index] = true
			alphabet_seen[alphabet_index] = true
			key_inverse[key_index] = i
			alphabet_inverse[alphabet_index] = i
		}
		mut output_length := 0
		for i in 0 .. text_length {
			value := input[54 + i]
			if !(value == 32 || (value >= 48 && value <= 57) ||
				(value >= 65 && value <= 90) || (value >= 97 && value <= 122)) { return -1 }
			if value < 48 || value > 57 { output_length++ }
		}

		mut hash := fnv_offset_basis
		length_word := u64(output_length)
		for byte in 0 .. 8 {
			hash = (hash ^ ((length_word >> (byte * 8)) & 255)) * fnv_prime
		}
		for i in 0 .. text_length {
			value := input[54 + i]
			if value >= 48 && value <= 57 { continue }
			mut mapped := value
			if value != 32 {
				lower := value >= 97 && value <= 122
				letter := int(value - 65)
				if lower { letter = int(value - 97) }
				position := if operation == 0 { alphabet_inverse[letter] } else { key_inverse[letter] }
				target := if operation == 0 { input[2 + position] } else { input[28 + position] }
				if lower { mapped = target + 32 } else { mapped = target }
			}
			hash = (hash ^ u64(mapped)) * fnv_prime
		}
		return i64(hash & mask_63)
	}
}

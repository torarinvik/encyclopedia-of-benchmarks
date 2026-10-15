module anyto_any

const max_encoded_value = i64(999_999_999)

@[export: 'anyto_any']
pub fn anyto_any(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 3 { return -1 }
	unsafe {
		mut encoded := input[0]
		source_base := input[1]
		destination_base := input[2]
		if encoded < 0 || encoded > max_encoded_value || source_base < 2 || source_base > 10 ||
			destination_base < 2 || destination_base > 10 { return -1 }

		mut decimal_value := i64(0)
		mut source_multiplier := i64(1)
		for encoded > 0 {
			digit := encoded % 10
			if digit >= source_base { return -1 }
			decimal_value += digit * source_multiplier
			source_multiplier *= source_base
			encoded /= 10
		}

		mut result := i64(0)
		mut destination_multiplier := i64(1)
		for decimal_value > 0 {
			digit := decimal_value % destination_base
			result += digit * destination_multiplier
			decimal_value /= destination_base
			if decimal_value > 0 {
				if destination_multiplier > max_encoded_value / 10 { return -1 }
				destination_multiplier *= 10
			}
		}
		return result
	}
}

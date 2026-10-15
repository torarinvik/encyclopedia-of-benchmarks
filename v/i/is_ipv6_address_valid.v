module is_ipv6_address_valid

const max_input_length = 256

fn is_hex_digit(value i64) bool {
	return (value >= 48 && value <= 57) || (value >= 97 && value <= 102) || (value >= 65 && value <= 70)
}

fn valid_ipv6_text(input &i64, text_length int) bool {
	if text_length == 0 { return false }
	mut groups := 0
	mut group_length := 0
	mut compression_count := 0
	mut in_group := false
	mut index := 0
	for index < text_length {
		value := unsafe { input[index + 1] }
		if value == 58 {
			if index + 1 < text_length && unsafe { input[index + 2] == 58 } {
				if (index > 0 && unsafe { input[index] == 58 }) ||
					(index + 2 < text_length && unsafe { input[index + 3] == 58 }) || compression_count != 0 {
					return false
				}
				if in_group {
					groups++
					in_group = false
					group_length = 0
				} else if index != 0 {
					return false
				}
				compression_count++
				index += 2
				continue
			}
			if index == 0 || index + 1 == text_length || !in_group { return false }
			groups++
			in_group = false
			group_length = 0
			index++
			continue
		}
		if !is_hex_digit(value) || group_length == 4 { return false }
		group_length++
		in_group = true
		index++
	}
	if in_group { groups++ }
	return if compression_count == 0 { groups == 8 } else { groups < 8 }
}

@[export: 'is_ipv6_address_valid']
pub fn is_ipv6_address_valid(input &i64, length usize) i64 {
	if length < 1 { return -1 }
	if unsafe { input[0] } < 0 || unsafe { input[0] } > max_input_length { return -1 }
	text_length := int(unsafe { input[0] })
	if int(length) != text_length + 1 { return -1 }
	for index in 0 .. text_length {
		value := unsafe { input[index + 1] }
		if value < 0 || value > 127 { return -1 }
	}
	if valid_ipv6_text(input, text_length) { return 1 }
	return 0
}

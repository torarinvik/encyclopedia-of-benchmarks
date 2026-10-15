module is_ip_v4_address_valid

const max_input_length = 32

@[export: 'is_ip_v4_address_valid']
pub fn is_ip_v4_address_valid(bytes &i64, length usize) i64 {
	if length > max_input_length { return -1 }
	for index in 0 .. length {
		value := unsafe { bytes[index] }
		if value < 0 || value > 127 { return -1 }
	}
	mut segment_count := 0
	mut digit_count := 0
	mut octet := i64(0)
	mut leading_zero := false
	for index in 0 .. length {
		value := unsafe { bytes[index] }
		if value == 46 {
			if digit_count == 0 || octet > 255 || segment_count >= 3 { return 0 }
			segment_count++
			digit_count = 0
			octet = 0
			leading_zero = false
		} else {
			if value < 48 || value > 57 { return 0 }
			if digit_count == 0 { leading_zero = value == 48 }
			else if leading_zero { return 0 }
			octet = octet * 10 + value - 48
			if octet > 255 { return 0 }
			digit_count++
			if digit_count > 3 { return 0 }
		}
	}
	return if segment_count == 3 && digit_count > 0 && octet <= 255 { 1 } else { 0 }
}

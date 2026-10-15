package is_ip_v4_address_valid

import "core:c"

MAX_INPUT_LENGTH :: 32

@(export)
is_ip_v4_address_valid :: proc "c" (bytes: [^]i64, length: c.size_t) -> i64 {
	if (bytes == nil && length != 0) || length > MAX_INPUT_LENGTH do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if bytes[index] < 0 || bytes[index] > 127 do return -1
	}
	segment_count := c.size_t(0)
	digit_count := c.size_t(0)
	octet: i64 = 0
	leading_zero := false
	for index := c.size_t(0); index < length; index += 1 {
		value := bytes[index]
		if value == 46 {
			if digit_count == 0 || octet > 255 || segment_count >= 3 do return 0
			segment_count += 1
			digit_count = 0
			octet = 0
			leading_zero = false
		} else {
			if value < 48 || value > 57 do return 0
			if digit_count == 0 do leading_zero = value == 48
			else if leading_zero do return 0
			octet = octet * 10 + value - 48
			if octet > 255 do return 0
			digit_count += 1
			if digit_count > 3 do return 0
		}
	}
	return i64(segment_count == 3 && digit_count > 0 && octet <= 255)
}

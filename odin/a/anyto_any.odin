package anyto_any

import "core:c"

MAX_ENCODED_VALUE :: i64(999999999)

@(export)
anyto_any :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != c.size_t(3) do return -1
	encoded := input[0]
	source_base := input[1]
	destination_base := input[2]
	if encoded < 0 || encoded > MAX_ENCODED_VALUE || source_base < 2 || source_base > 10 || destination_base < 2 || destination_base > 10 do return -1

	decimal_value: i64 = 0
	source_multiplier: i64 = 1
	for encoded > 0 {
		digit := encoded % 10
		if digit >= source_base do return -1
		decimal_value += digit * source_multiplier
		source_multiplier *= source_base
		encoded /= 10
	}

	result: i64 = 0
	destination_multiplier: i64 = 1
	for decimal_value > 0 {
		digit := decimal_value % destination_base
		result += digit * destination_multiplier
		decimal_value /= destination_base
		if decimal_value > 0 {
			if destination_multiplier > MAX_ENCODED_VALUE / 10 do return -1
			destination_multiplier *= 10
		}
	}
	return result
}

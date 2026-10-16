package ipv4_conversion

import "core:c"

Invalid_Result :: i64(-9223372036854775807 - 1)

@(export)
ipv4_conversion :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 4 do return Invalid_Result
	address: i64 = 0
	for index := 0; index < 4; index += 1 {
		octet := input[index]
		if octet < 0 || octet > 255 do return Invalid_Result
		address = address * 256 + octet
	}
	return address
}

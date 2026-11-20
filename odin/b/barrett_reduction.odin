package barrett_reduction

import "core:c"

RADIX :: i64(4294967296)
MAX_MODULUS :: i64(65535)
MAX_VALUES :: 12
MAX_LENGTH :: 15

@(export)
barrett_reduction :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_LENGTH) do return -1
	modulus := input[0]
	count_value := input[1]
	if modulus < 2 || modulus > MAX_MODULUS || count_value < 0 || count_value > MAX_VALUES do return -1
	count := int(count_value)
	if length != c.size_t(2+count) do return -1
	square_bound := modulus*modulus
	for i := 0; i < count; i += 1 {
		if input[2+i] < 0 || input[2+i] >= square_bound do return -1
	}
	reciprocal := RADIX/modulus
	checksum := i64(0)
	for i := 0; i < count; i += 1 {
		value := input[2+i]
		quotient := (value*reciprocal)/RADIX
		remainder := value-quotient*modulus
		if remainder >= modulus { remainder -= modulus }
		checksum += i64(i+1)*(remainder+1)
	}
	return checksum
}

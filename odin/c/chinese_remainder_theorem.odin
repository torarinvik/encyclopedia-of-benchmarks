package chinese_remainder_theorem

import "core:c"

MAX_INPUTS :: 8
MAX_MODULUS :: i64(1000)

modular_inverse :: proc "contextless" (value, modulus: i64) -> i64 {
	old_remainder := value % modulus
	remainder := modulus
	old_coefficient := i64(1)
	coefficient := i64(0)
	for remainder != 0 {
		quotient := old_remainder / remainder
		next_remainder := old_remainder - quotient * remainder
		old_remainder = remainder
		remainder = next_remainder
		next_coefficient := old_coefficient - quotient * coefficient
		old_coefficient = coefficient
		coefficient = next_coefficient
	}
	if old_remainder != 1 do return -1
	old_coefficient %= modulus
	if old_coefficient < 0 do old_coefficient += modulus
	return old_coefficient
}

@(export)
chinese_remainder_theorem :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length < 2 || length > c.size_t(MAX_INPUTS) || length % 2 != 0 do return -1
	result := i64(0)
	product := i64(1)
	for index := 0; index < int(length); index += 2 {
		residue := values[index]
		modulus := values[index + 1]
		if modulus < 2 || modulus > MAX_MODULUS || residue < 0 || residue >= modulus do return -1
		inverse := modular_inverse(product % modulus, modulus)
		if inverse < 0 do return -1
		difference := residue - result % modulus
		if difference < 0 do difference += modulus
		factor := difference * inverse % modulus
		result += product * factor
		product *= modulus
	}
	return result
}

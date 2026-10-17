package rsa_cipher

import "core:c"

@(export)
rsa_cipher_encrypt_ascii :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 3 do return -1
	base_input := values[0]
	exponent_input := values[1]
	modulus := values[2]
	if base_input < 0 || base_input > 127 || modulus < 128 || modulus > 65535 ||
		exponent_input < 1 || exponent_input >= modulus {
		return -1
	}
	base := u64(base_input)
	exponent := u64(exponent_input)
	unsigned_modulus := u64(modulus)
	result := u64(1)
	base %= unsigned_modulus
	for exponent > 0 {
		if exponent % 2 == 1 do result = (result * base) % unsigned_modulus
		exponent >>= 1
		base = (base * base) % unsigned_modulus
	}
	return i64(result)
}

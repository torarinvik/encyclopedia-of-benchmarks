package rsa_java_big_integer

import "core:c"

INVALID_RESULT :: i64 = -1
MAX_INPUT_LENGTH :: c.size_t = 69
FNV_OFFSET_BASIS :: u64 = 14695981039346656037
FNV_PRIME :: u64 = 1099511628211
LOW_63_MASK :: u64 = 0x7fffffffffffffff

big_integer_mod_pow :: proc "contextless" (base, exponent_input, modulus: i64) -> i64 {
	exponent := exponent_input
	result := i64(1)
	power := base % modulus
	for exponent > 0 {
		if exponent&1 != 0 do result = (result * power) % modulus
		power = (power * power) % modulus
		exponent /= 2
	}
	return result
}

hash_u32 :: proc "contextless" (hash_input: u64, value: i64) -> u64 {
	hash := hash_input
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 {
		hash = (hash ^ u64(u8(bits >> u32(byte*8)))) * FNV_PRIME
	}
	return hash
}

@(export)
rsa_java_big_integer :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 5 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	modulus, public_exponent, private_exponent, message_length := packed[0], packed[1], packed[2], packed[3]
	if modulus < 128 || modulus > 55295 || public_exponent < 1 || public_exponent > 1000000 ||
		private_exponent < 1 || private_exponent > 1000000 || message_length < 1 || message_length > 64 ||
		length != c.size_t(4 + message_length) do return INVALID_RESULT
	for i := c.size_t(0); i < c.size_t(message_length); i += 1 {
		value := packed[4 + i]
		if value < 0 || value > 127 || value >= modulus do return INVALID_RESULT
	}
	hash := FNV_OFFSET_BASIS
	for i := c.size_t(0); i < c.size_t(message_length); i += 1 {
		hash = hash_u32(hash, big_integer_mod_pow(packed[4+i], public_exponent, modulus))
	}
	for i := c.size_t(0); i < c.size_t(message_length); i += 1 {
		ciphertext := big_integer_mod_pow(packed[4+i], public_exponent, modulus)
		hash = hash_u32(hash, big_integer_mod_pow(ciphertext, private_exponent, modulus))
	}
	return i64(hash & LOW_63_MASK)
}

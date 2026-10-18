package rsa_ruby_byte_chunk

import "core:c"

INVALID_RESULT :: i64 = -1
MAX_INPUT_LENGTH :: c.size_t = 69
FNV_OFFSET_BASIS :: u64 = 14695981039346656037
FNV_PRIME :: u64 = 1099511628211
LOW_63_MASK :: u64 = 0x7fffffffffffffff

bounded_power :: proc "contextless" (base, exponent: i64) -> i64 {
	result := i64(1)
	for i := i64(0); i < exponent; i += 1 { result *= base }
	return result
}

hash_byte :: proc "contextless" (hash_input: u64, value: u8) -> u64 {
	return (hash_input ^ u64(value)) * FNV_PRIME
}

@(export)
rsa_ruby_byte_chunk :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 5 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	modulus, public_exponent, private_exponent, message_length := packed[0], packed[1], packed[2], packed[3]
	if modulus != 33 || public_exponent < 1 || public_exponent > 7 || private_exponent < 1 || private_exponent > 7 ||
		message_length < 1 || message_length > 64 || length != c.size_t(4 + message_length) do return INVALID_RESULT
	for i := c.size_t(0); i < c.size_t(message_length); i += 1 {
		if packed[4+i] < 0 || packed[4+i] >= modulus do return INVALID_RESULT
	}
	var ciphertexts: [64]i64
	for i := c.size_t(0); i < c.size_t(message_length); i += 1 {
		ciphertexts[i] = bounded_power(packed[4+i], public_exponent) % modulus
	}
	hash := FNV_OFFSET_BASIS
	for i := c.size_t(0); i < c.size_t(message_length); i += 1 {
		value := ciphertexts[i]
		hash = hash_byte(hash, u8(48 + value/10))
		hash = hash_byte(hash, u8(48 + value%10))
	}
	for i := c.size_t(0); i < c.size_t(message_length); i += 1 {
		recovered := bounded_power(ciphertexts[i], private_exponent) % modulus
		hash = hash_byte(hash, u8(recovered))
	}
	return i64(hash & LOW_63_MASK)
}

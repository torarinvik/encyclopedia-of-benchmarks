module rsa_ruby_byte_chunk

const invalid_result = i64(-1)
const max_input_length = usize(69)
const fnv_offset_basis = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)
const low63_mask = u64(0x7fffffffffffffff)

fn bounded_power(base i64, exponent i64) i64 {
	mut result := i64(1)
	for _ in 0 .. int(exponent) { result *= base }
	return result
}

fn hash_byte(hash_input u64, value u8) u64 {
	return (hash_input ^ u64(value)) *% fnv_prime
}

@[export: 'rsa_ruby_byte_chunk']
pub fn rsa_ruby_byte_chunk(packed &i64, length usize) i64 {
	if packed == nil || length < 5 || length > max_input_length { return invalid_result }
	unsafe {
		modulus, public_exponent, private_exponent, message_length := packed[0], packed[1], packed[2], packed[3]
		if modulus != 33 || public_exponent < 1 || public_exponent > 7 || private_exponent < 1 || private_exponent > 7 ||
			message_length < 1 || message_length > 64 || length != usize(4 + message_length) { return invalid_result }
		for i in 0 .. int(message_length) {
			if packed[4 + i] < 0 || packed[4 + i] >= modulus { return invalid_result }
		}
		mut ciphertexts := []i64{cap: int(message_length)}
		for i in 0 .. int(message_length) {
			ciphertexts << bounded_power(packed[4 + i], public_exponent) % modulus
		}
		mut hash := fnv_offset_basis
		for value in ciphertexts {
			hash = hash_byte(hash, u8(48 + value / 10))
			hash = hash_byte(hash, u8(48 + value % 10))
		}
		for ciphertext in ciphertexts {
			recovered := bounded_power(ciphertext, private_exponent) % modulus
			hash = hash_byte(hash, u8(recovered))
		}
		return i64(hash & low63_mask)
	}
}

module rsa_java_big_integer

const invalid_result = i64(-1)
const max_input_length = usize(69)
const fnv_offset_basis = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)
const low63_mask = u64(0x7fffffffffffffff)

fn big_integer_mod_pow(base i64, exponent_input i64, modulus i64) i64 {
	mut exponent := exponent_input
	mut result := i64(1)
	mut power := base % modulus
	for exponent > 0 {
		if exponent & 1 != 0 { result = (result * power) % modulus }
		power = (power * power) % modulus
		exponent /= 2
	}
	return result
}

fn hash_u32(hash_input u64, value i64) u64 {
	mut hash := hash_input
	bits := u32(value)
	for byte in 0 .. 4 {
		hash = (hash ^ u64((bits >> (byte * 8)) & u32(255))) *% fnv_prime
	}
	return hash
}

@[export: 'rsa_java_big_integer']
pub fn rsa_java_big_integer(packed &i64, length usize) i64 {
	if packed == nil || length < 5 || length > max_input_length { return invalid_result }
	unsafe {
		modulus, public_exponent, private_exponent, message_length := packed[0], packed[1], packed[2], packed[3]
		if modulus < 128 || modulus > 55295 || public_exponent < 1 || public_exponent > 1000000 ||
			private_exponent < 1 || private_exponent > 1000000 || message_length < 1 || message_length > 64 ||
			length != usize(4 + message_length) { return invalid_result }
		for i in 0 .. int(message_length) {
			value := packed[4 + i]
			if value < 0 || value > 127 || value >= modulus { return invalid_result }
		}
		mut hash := fnv_offset_basis
		for i in 0 .. int(message_length) {
			hash = hash_u32(hash, big_integer_mod_pow(packed[4 + i], public_exponent, modulus))
		}
		for i in 0 .. int(message_length) {
			ciphertext := big_integer_mod_pow(packed[4 + i], public_exponent, modulus)
			hash = hash_u32(hash, big_integer_mod_pow(ciphertext, private_exponent, modulus))
		}
		return i64(hash & low63_mask)
	}
}

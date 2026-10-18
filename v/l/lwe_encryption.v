module lwe_encryption

const invalid_result = i64(-1)
const dimension = 32
const modulus = i64(3329)
const samples = 128
const max_message_bytes = 4
const max_parseable_length = 8358
const fnv_offset_basis = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)
const low63_mask = u64(0x7fffffffffffffff)

fn hash_byte(hash_input u64, byte u8) u64 {
	return (hash_input ^ u64(byte)) * fnv_prime
}

fn hash_word(hash_input u64, value i64) u64 {
	mut hash := hash_input
	word := u64(value)
	hash = hash_byte(hash, u8(word & u64(255)))
	hash = hash_byte(hash, u8((word >> 8) & u64(255)))
	return hash
}

@[export: 'lwe_encryption']
pub fn lwe_encryption(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 1 || length > max_parseable_length { return invalid_result }
		message_length_value := values[0]
		if message_length_value < 1 || message_length_value > i64(max_message_bytes) { return invalid_result }
		message_length := int(message_length_value)
		message_start := 1
		message_end := message_start + message_length
		secret_start := message_end
		matrix_start := secret_start + dimension
		error_start := matrix_start + samples * dimension
		subset_start := error_start + samples
		subset_count := message_length * 8 * samples
		if int(length) != subset_start + subset_count { return invalid_result }

		for i in 0 .. message_length { if values[message_start + i] < 0 || values[message_start + i] > 255 { return invalid_result } }
		for j in 0 .. dimension { if values[secret_start + j] < 0 || values[secret_start + j] >= modulus { return invalid_result } }
		for i in 0 .. samples * dimension { if values[matrix_start + i] < 0 || values[matrix_start + i] >= modulus { return invalid_result } }
		for i in 0 .. samples { if values[error_start + i] < 0 || values[error_start + i] > 6 { return invalid_result } }
		for i in 0 .. subset_count { if values[subset_start + i] != 0 && values[subset_start + i] != 1 { return invalid_result } }

		mut public_b := [128]i64{}
		for row in 0 .. samples {
			mut sum := i64(0)
			for column in 0 .. dimension { sum += values[matrix_start + row * dimension + column] * values[secret_start + column] }
			error := values[error_start + row] - 3
			mut reduced := (sum + error) % modulus
			if reduced < 0 { reduced += modulus }
			public_b[row] = reduced
		}

		mut hash := fnv_offset_basis
		mut decoded_message := [4]u8{}
		mut subset_cursor := 0
		for byte_index in 0 .. message_length {
			message_byte := u8(values[message_start + byte_index])
			mut decoded_byte := u8(0)
			for bit_index in 0 .. 8 {
				message_bit := i64((int(message_byte) >> (7 - bit_index)) & 1)
				mut u_accumulator := [32]i64{}
				mut v_accumulator := message_bit * (modulus / 2)
				for row in 0 .. samples {
					selected := values[subset_start + subset_cursor]
					subset_cursor++
					if selected != 0 {
						for column in 0 .. dimension { u_accumulator[column] += values[matrix_start + row * dimension + column] }
						v_accumulator += public_b[row]
					}
				}
				mut u := [32]i64{}
				for column in 0 .. dimension {
					u[column] = u_accumulator[column] % modulus
					hash = hash_word(hash, u[column])
				}
				v := v_accumulator % modulus
				hash = hash_word(hash, v)

				mut dot := i64(0)
				for column in 0 .. dimension { dot += u[column] * values[secret_start + column] }
				mut difference := (v - dot) % modulus
				if difference < 0 { difference += modulus }
				decrypted_bit := if difference >= 832 && difference < 2496 { u8(1) } else { u8(0) }
				decoded_byte = (decoded_byte << 1) | decrypted_bit
			}
			decoded_message[byte_index] = decoded_byte
		}
		for i in 0 .. message_length { hash = hash_byte(hash, decoded_message[i]) }
		return i64(hash & low63_mask)
	}
}

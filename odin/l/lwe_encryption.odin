package lwe_encryption

import "core:c"

INVALID_RESULT :: i64 = -1
DIMENSION :: int = 32
MODULUS :: i64 = 3329
SAMPLES :: int = 128
MAX_MESSAGE_BYTES :: int = 4
MAX_PARSEABLE_LENGTH :: c.size_t = 8358
FNV_OFFSET_BASIS :: u64 = 14695981039346656037
FNV_PRIME :: u64 = 1099511628211
LOW_63_MASK :: u64 = 0x7fffffffffffffff

hash_byte :: proc "contextless" (hash_input: u64, byte: u8) -> u64 {
	return (hash_input ^ u64(byte)) * FNV_PRIME
}

hash_word :: proc "contextless" (hash_input: u64, value: i64) -> u64 {
	hash := hash_input
	bits := transmute(u64(value))
	hash = hash_byte(hash, u8(bits & 255))
	hash = hash_byte(hash, u8((bits >> 8) & 255))
	return hash
}

@(export)
lwe_encryption :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > MAX_PARSEABLE_LENGTH do return INVALID_RESULT
	message_length_value := values[0]
	if message_length_value < 1 || message_length_value > i64(MAX_MESSAGE_BYTES) do return INVALID_RESULT
	message_length := int(message_length_value)
	message_start := 1
	message_end := message_start + message_length
	secret_start := message_end
	matrix_start := secret_start + DIMENSION
	error_start := matrix_start + SAMPLES*DIMENSION
	subset_start := error_start + SAMPLES
	subset_count := message_length*8*SAMPLES
	if int(length) != subset_start+subset_count do return INVALID_RESULT

	for i := 0; i < message_length; i += 1 {
		if values[message_start+i] < 0 || values[message_start+i] > 255 do return INVALID_RESULT
	}
	for j := 0; j < DIMENSION; j += 1 {
		if values[secret_start+j] < 0 || values[secret_start+j] >= MODULUS do return INVALID_RESULT
	}
	for i := 0; i < SAMPLES*DIMENSION; i += 1 {
		if values[matrix_start+i] < 0 || values[matrix_start+i] >= MODULUS do return INVALID_RESULT
	}
	for i := 0; i < SAMPLES; i += 1 {
		if values[error_start+i] < 0 || values[error_start+i] > 6 do return INVALID_RESULT
	}
	for i := 0; i < subset_count; i += 1 {
		if values[subset_start+i] != 0 && values[subset_start+i] != 1 do return INVALID_RESULT
	}

	public_b: [128]i64
	for row := 0; row < SAMPLES; row += 1 {
		sum := i64(0)
		for column := 0; column < DIMENSION; column += 1 {
			sum += values[matrix_start+row*DIMENSION+column] * values[secret_start+column]
		}
		error := values[error_start+row]-3
		reduced := (sum+error)%MODULUS
		if reduced < 0 do reduced += MODULUS
		public_b[row] = reduced
	}

	hash := FNV_OFFSET_BASIS
	decoded_message: [4]u8
	subset_cursor := 0
	for byte_index := 0; byte_index < message_length; byte_index += 1 {
		message_byte := u8(values[message_start+byte_index])
		decoded_byte := u8(0)
		for bit_index := 0; bit_index < 8; bit_index += 1 {
			message_bit := i64((message_byte >> u8(7-bit_index)) & 1)
			u_accumulator: [32]i64
			v_accumulator := message_bit * (MODULUS/2)
			for row := 0; row < SAMPLES; row += 1 {
				selected := values[subset_start+subset_cursor]
				subset_cursor += 1
				if selected != 0 {
					for column := 0; column < DIMENSION; column += 1 {
						u_accumulator[column] += values[matrix_start+row*DIMENSION+column]
					}
					v_accumulator += public_b[row]
				}
			}
			u: [32]i64
			for column := 0; column < DIMENSION; column += 1 {
				u[column] = u_accumulator[column]%MODULUS
				hash = hash_word(hash,u[column])
			}
			v := v_accumulator%MODULUS
			hash = hash_word(hash,v)
			dot := i64(0)
			for column := 0; column < DIMENSION; column += 1 { dot += u[column]*values[secret_start+column] }
			difference := (v-dot)%MODULUS
			if difference < 0 do difference += MODULUS
			decrypted_bit := u8(0)
			if difference >= 832 && difference < 2496 do decrypted_bit = 1
			decoded_byte = (decoded_byte<<1)|decrypted_bit
		}
		decoded_message[byte_index] = decoded_byte
	}
	for i := 0; i < message_length; i += 1 { hash = hash_byte(hash,decoded_message[i]) }
	return i64(hash&LOW_63_MASK)
}

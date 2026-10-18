module sha3

const max_message_bytes = 4096
const max_parseable_input_length = 4099
const max_output_bytes = 64
const round_constants = [24]u64{
	u64(0x0000000000000001),u64(0x0000000000008082),u64(0x800000000000808a),u64(0x8000000080008000),
	u64(0x000000000000808b),u64(0x0000000080000001),u64(0x8000000080008081),u64(0x8000000000008009),
	u64(0x000000000000008a),u64(0x0000000000000088),u64(0x0000000080008009),u64(0x000000008000000a),
	u64(0x000000008000808b),u64(0x800000000000008b),u64(0x8000000080008089),u64(0x8000000000008003),
	u64(0x8000000000008002),u64(0x8000000000000080),u64(0x000000000000800a),u64(0x800000008000000a),
	u64(0x8000000080008081),u64(0x8000000000008080),u64(0x0000000080000001),u64(0x8000000080008008),
}
const rotation_offsets = [25]u32{0,1,62,28,27,36,44,6,55,20,3,10,43,25,39,41,45,15,21,8,18,2,61,56,14}

fn sha3_rotate_left(value u64, amount int) u64 {
	if amount == 0 { return value }
	return (value << amount) | (value >> (64 - amount))
}

fn sha3_keccak_f(mut state &u64) {
	for round in 0 .. 24 {
		mut column := [5]u64{}
		mut delta := [5]u64{}
		mut moved := [25]u64{}
		for x in 0 .. 5 { column[x] = state[x] ^ state[x + 5] ^ state[x + 10] ^ state[x + 15] ^ state[x + 20] }
		for x in 0 .. 5 { delta[x] = column[(x + 4) % 5] ^ sha3_rotate_left(column[(x + 1) % 5], 1) }
		for y in 0 .. 5 { for x in 0 .. 5 { state[x + 5 * y] ^= delta[x] } }
		for y in 0 .. 5 {
			for x in 0 .. 5 {
				source := x + 5 * y
				target := y + 5 * ((2 * x + 3 * y) % 5)
				moved[target] = sha3_rotate_left(state[source], int(rotation_offsets[source]))
			}
		}
		for y in 0 .. 5 {
			for x in 0 .. 5 {
				state[x + 5 * y] = moved[x + 5 * y] ^ ((~moved[(x + 1) % 5 + 5 * y]) & moved[(x + 2) % 5 + 5 * y])
			}
		}
		state[0] ^= round_constants[round]
	}
}

fn sha3_absorb_byte(mut state &u64, offset int, value u8) {
	state[offset / 8] ^= u64(value) << ((offset % 8) * 8)
}

fn sha3_digest(variant int, input &i64, message_length int) [64]u8 {
	digest_lengths := [4]int{28,32,48,64}
	rates := [4]int{144,136,104,72}
	rate := rates[variant]
	mut state := [25]u64{}
	mut offset := 0
	for message_length - offset >= rate {
		for index in 0 .. rate { sha3_absorb_byte(mut state[0], index, u8(input[2 + offset + index])) }
		sha3_keccak_f(mut state[0])
		offset += rate
	}
	mut block := [144]u8{}
	remaining := message_length - offset
	for index in 0 .. remaining { block[index] = u8(input[2 + offset + index]) }
	block[remaining] ^= 0x06
	block[rate - 1] ^= 0x80
	for index in 0 .. rate { sha3_absorb_byte(mut state[0], index, block[index]) }
	sha3_keccak_f(mut state[0])
	mut digest := [64]u8{}
	for index in 0 .. digest_lengths[variant] { digest[index] = u8((state[index / 8] >> ((index % 8) * 8)) & 255) }
	return digest
}

@[export: 'sha3']
pub fn sha3(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > usize(max_parseable_input_length) { return -1 }
		if input[0] < 0 || input[0] > 3 || input[1] < 0 || input[1] > max_message_bytes { return -1 }
		variant, message_length := int(input[0]), int(input[1])
		if int(input_length) != 2 + message_length { return -1 }
		for index in 0 .. message_length { if input[2 + index] < 0 || input[2 + index] > 255 { return -1 } }
		digest_lengths := [4]int{28,32,48,64}
		digest_length := digest_lengths[variant]
		if digest_length > max_output_bytes { return -1 }
		if output == nil || output_capacity < usize(digest_length) { return -2 }
		digest := sha3_digest(variant, input, message_length)
		for index in 0 .. digest_length { output[index] = digest[index] }
		return i64(digest_length)
	}
}

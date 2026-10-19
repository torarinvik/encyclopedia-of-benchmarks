// ARC4 port from Trimaran/enc-rc4, Copyright (C) 2001-2003 Christophe Devine.
// Distributed under GPL-2.0-or-later; see the package license notice.
module trimaran_enc_rc4

const output_bytes = 82
const max_passes = i64(2000)
const key_lengths = [6]int{8, 8, 8, 4, 8, 4}
const data_lengths = [6]int{8, 8, 8, 20, 28, 10}
const output_offsets = [6]int{0, 8, 16, 24, 44, 72}

fn crypt_one(keys &u8, key_base int, key_length int, mut staged &u8, data_base int, data_length int) {
	unsafe {
		mut state := [256]int{}
		for index in 0 .. 256 { state[index] = index }
		mut j := 0
		for index in 0 .. 256 {
			j = (j + state[index] + int(keys[key_base + index % key_length])) % 256
			state[index], state[j] = state[j], state[index]
		}
		mut x := 0
		j = 0
		for offset in 0 .. data_length {
			x = (x + 1) % 256
			a := state[x]
			j = (j + a) % 256
			b := state[j]
			state[x], state[j] = b, a
			staged[data_base + offset] ^= u8(state[(a + b) % 256])
		}
	}
}

@[export: 'trimaran_enc_rc4']
pub fn trimaran_enc_rc4(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length != 1 { return -1 }
		passes := input[0]
		if passes < 1 || passes > max_passes { return -1 }
		if output == nil || output_capacity < output_bytes { return -2 }

		mut keys := [48]u8{}
		key_a := [8]u8{0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef}
		key_b := [4]u8{0xef, 0x01, 0x23, 0x45}
		for index in 0 .. 8 {
			keys[index] = key_a[index]
			keys[8 + index] = key_a[index]
			keys[32 + index] = key_a[index]
		}
		for index in 0 .. 4 {
			keys[24 + index] = key_b[index]
			keys[40 + index] = key_b[index]
		}
		mut plaintexts := [168]u8{}
		data_a := [8]u8{0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef}
		data_b := [28]u8{0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0,
			0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0,
			0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0,
			0x12, 0x34, 0x56, 0x78}
		for index in 0 .. 8 { plaintexts[index] = data_a[index] }
		for index in 0 .. 28 { plaintexts[112 + index] = data_b[index] }
		mut staged := [output_bytes]u8{}
		for vector in 0 .. 6 {
			output_base := output_offsets[vector]
			input_base := vector * 28
			for _ in 0 .. int(passes) {
				for byte in 0 .. data_lengths[vector] { staged[output_base + byte] = plaintexts[input_base + byte] }
				crypt_one(keys[0], vector * 8, key_lengths[vector], mut staged[0], output_base, data_lengths[vector])
			}
		}
		for index in 0 .. output_bytes { output[index] = staged[index] }
		return i64(output_bytes)
	}
}

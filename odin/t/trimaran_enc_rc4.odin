// ARC4 port from Trimaran/enc-rc4, Copyright (C) 2001-2003 Christophe Devine.
// Distributed under GPL-2.0-or-later; see the package license notice.
package trimaran_enc_rc4

import "core:c"

OUTPUT_BYTES :: 82
MAX_PASSES :: 2000
KEY_LENGTHS :: [6]int{8, 8, 8, 4, 8, 4}
DATA_LENGTHS :: [6]int{8, 8, 8, 20, 28, 10}
OUTPUT_OFFSETS :: [6]int{0, 8, 16, 24, 44, 72}

crypt_one :: proc(keys: [^]u8, key_base, key_length: int, staged: [^]u8, data_base, data_length: int) {
	state: [256]int = {}
	for index := 0; index < 256; index += 1 do state[index] = index
	j := 0
	for index := 0; index < 256; index += 1 {
		j = (j + state[index] + int(keys[key_base + index % key_length])) % 256
		temp := state[index]
		state[index] = state[j]
		state[j] = temp
	}
	x := 0
	j = 0
	for offset := 0; offset < data_length; offset += 1 {
		x = (x + 1) % 256
		a := state[x]
		j = (j + a) % 256
		b := state[j]
		state[x] = b
		state[j] = a
		staged[data_base + offset] ^= u8(state[(a + b) % 256])
	}
}

@(export, link_name="trimaran_enc_rc4")
trimaran_enc_rc4 :: proc "c" (input: [^]i64, length: c.size_t,
									 output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	passes := input[0]
	if passes < 1 || passes > MAX_PASSES do return -1
	if output == nil || output_capacity < OUTPUT_BYTES do return -2

	keys: [48]u8 = {}
	key_a := [8]u8{0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef}
	key_b := [4]u8{0xef, 0x01, 0x23, 0x45}
	for index := 0; index < 8; index += 1 {
		keys[index] = key_a[index]
		keys[8 + index] = key_a[index]
		keys[32 + index] = key_a[index]
	}
	for index := 0; index < 4; index += 1 {
		keys[24 + index] = key_b[index]
		keys[40 + index] = key_b[index]
	}
	plaintexts: [168]u8 = {}
	data_a := [8]u8{0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef}
	data_b := [28]u8{0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0,
		0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0,
		0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0,
		0x12, 0x34, 0x56, 0x78}
	for index := 0; index < 8; index += 1 do plaintexts[index] = data_a[index]
	for index := 0; index < 28; index += 1 do plaintexts[112 + index] = data_b[index]
	staged: [OUTPUT_BYTES]u8 = {}
	for vector := 0; vector < 6; vector += 1 {
		output_base := OUTPUT_OFFSETS[vector]
		input_base := vector * 28
		for pass := i64(0); pass < passes; pass += 1 {
			for byte := 0; byte < DATA_LENGTHS[vector]; byte += 1 do staged[output_base + byte] = plaintexts[input_base + byte]
			crypt_one(&keys[0], vector * 8, KEY_LENGTHS[vector], &staged[0], output_base, DATA_LENGTHS[vector])
		}
	}
	for index := 0; index < OUTPUT_BYTES; index += 1 do output[index] = staged[index]
	return OUTPUT_BYTES
}

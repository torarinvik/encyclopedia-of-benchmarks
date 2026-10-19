package idea_encrypt_decrypt

import "core:c"

idea_mul :: proc "contextless" (left, right: u16) -> u16 {
	a := u64(left)
	b := u64(right)
	if left == 0 { a = 65536 }
	if right == 0 { b = 65536 }
	r := (a * b) % 65537
	if r == 65536 { return 0 }
	return u16(r)
}

idea_inverse :: proc "contextless" (value: u16) -> u16 {
	old_r: i64 = 65537
	r: i64 = i64(value)
	if value == 0 { r = 65536 }
	old_s: i64 = 0
	s: i64 = 1
	for r != 0 {
		q := old_r / r
		nr := old_r - q * r
		ns := old_s - q * s
		old_r = r; r = nr; old_s = s; s = ns
	}
	old_s %= 65537
	if old_s < 0 { old_s += 65537 }
	if old_s == 65536 { return 0 }
	return u16(old_s)
}

add16 :: proc "contextless" (a, b: u16) -> u16 { return u16((u32(a) + u32(b)) % 65536) }
sub16 :: proc "contextless" (a, b: u16) -> u16 { return u16((i32(a) - i32(b) + 65536) % 65536) }

expand_key :: proc "contextless" (key: [8]u16) -> [52]u16 {
	state := key
	keys: [52]u16
	for offset := 0; offset < 52; offset += 8 {
		amount := 52 - offset
		if amount > 8 { amount = 8 }
		for i := 0; i < amount; i += 1 { keys[offset + i] = state[i] }
		rotated: [8]u16
		for i := 0; i < 8; i += 1 { rotated[i] = u16((u32(state[(i + 1) & 7]) << 9) | (u32(state[(i + 2) & 7]) >> 7)) }
		state = rotated
	}
	return keys
}

encrypt_block :: proc "contextless" (key: [52]u16, plain_words: [4]u16) -> [4]u16 {
	x1, x2, x3, x4 := plain_words[0], plain_words[1], plain_words[2], plain_words[3]
	for round := 0; round < 8; round += 1 {
		k := round * 6
		a := idea_mul(x1, key[k]); b := add16(x2, key[k + 1]); c0 := add16(x3, key[k + 2]); d := idea_mul(x4, key[k + 3])
		p := idea_mul(a ^ c0, key[k + 4]); q := idea_mul(add16(b ^ d, p), key[k + 5]); r := add16(p, q)
		x1 = a ^ q; x2 = c0 ^ q; x3 = b ^ r; x4 = d ^ r
	}
	return [4]u16{idea_mul(x1, key[48]), add16(x3, key[49]), add16(x2, key[50]), idea_mul(x4, key[51])}
}

decrypt_block :: proc "contextless" (key: [52]u16, cipher: [4]u16) -> [4]u16 {
	x1 := idea_mul(cipher[0], idea_inverse(key[48])); x2 := sub16(cipher[2], key[50]); x3 := sub16(cipher[1], key[49]); x4 := idea_mul(cipher[3], idea_inverse(key[51]))
	for step := 8; step > 0; step -= 1 {
		k := (step - 1) * 6
		p := idea_mul(x1 ^ x2, key[k + 4]); q := idea_mul(add16(x3 ^ x4, p), key[k + 5]); r := add16(p, q)
		a := x1 ^ q; c0 := x2 ^ q; b := x3 ^ r; d := x4 ^ r
		x1 = idea_mul(a, idea_inverse(key[k])); x2 = sub16(b, key[k + 1]); x3 = sub16(c0, key[k + 2]); x4 = idea_mul(d, idea_inverse(key[k + 3]))
	}
	return [4]u16{x1, x2, x3, x4}
}

idea_encrypt_decrypt :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 12 do return -1
	key_words: [8]u16
	plain_words: [4]u16
	for i := c.size_t(0); i < 12; i += 1 {
		if input[i] < 0 || input[i] > 65535 do return -1
		if i < 8 { key_words[i] = u16(input[i]) } else { plain_words[i - 8] = u16(input[i]) }
	}
	if output == nil || capacity < 16 do return -2
	keys := expand_key(key_words)
	encrypted := encrypt_block(keys, plain_words)
	recovered := decrypt_block(keys, encrypted)
	for i := 0; i < 4; i += 1 {
		output[i * 2] = u8(encrypted[i]); output[i * 2 + 1] = u8(encrypted[i] >> 8)
		output[8 + i * 2] = u8(recovered[i]); output[9 + i * 2] = u8(recovered[i] >> 8)
	}
	return 16
}

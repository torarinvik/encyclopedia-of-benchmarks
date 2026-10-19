module idea_encrypt_decrypt

fn idea_mul(left u16, right u16) u16 {
	a := if left == 0 { u64(65536) } else { u64(left) }
	b := if right == 0 { u64(65536) } else { u64(right) }
	r := (a * b) % u64(65537)
	return if r == 65536 { u16(0) } else { u16(r) }
}

fn idea_inverse(value u16) u16 {
	mut old_r := i64(65537)
	mut r := if value == 0 { i64(65536) } else { i64(value) }
	mut old_s := i64(0)
	mut s := i64(1)
	for r != 0 {
		q := old_r / r
		nr := old_r - q * r
		ns := old_s - q * s
		old_r = r; r = nr; old_s = s; s = ns
	}
	mut residue := old_s % 65537
	if residue < 0 { residue += 65537 }
	return if residue == 65536 { u16(0) } else { u16(residue) }
}

fn add16(a u16, b u16) u16 { return u16((u32(a) + u32(b)) % u32(65536)) }
fn sub16(a u16, b u16) u16 { return u16((i32(a) - i32(b) + 65536) % 65536) }

fn expand_key(key []u16) []u16 {
	mut state := key.clone()
	mut keys := []u16{len: 52, init: 0}
	mut offset := 0
	for offset < 52 {
		amount := if 52 - offset < 8 { 52 - offset } else { 8 }
		for i := 0; i < amount; i++ { keys[offset + i] = state[i] }
		mut rotated := []u16{len: 8, init: 0}
		for i := 0; i < 8; i++ { rotated[i] = u16((u32(state[(i + 1) & 7]) << 9) | (u32(state[(i + 2) & 7]) >> 7)) }
		state = rotated
		offset += amount
	}
	return keys
}

fn encrypt_block(key []u16, plain_words []u16) []u16 {
	mut x1 := plain_words[0]; mut x2 := plain_words[1]; mut x3 := plain_words[2]; mut x4 := plain_words[3]
	for round := 0; round < 8; round++ {
		k := round * 6
		a := idea_mul(x1, key[k]); b := add16(x2, key[k + 1]); c := add16(x3, key[k + 2]); d := idea_mul(x4, key[k + 3])
		p := idea_mul(a ^ c, key[k + 4]); q := idea_mul(add16(b ^ d, p), key[k + 5]); r := add16(p, q)
		x1 = a ^ q; x2 = c ^ q; x3 = b ^ r; x4 = d ^ r
	}
	return [idea_mul(x1, key[48]), add16(x3, key[49]), add16(x2, key[50]), idea_mul(x4, key[51])]
}

fn decrypt_block(key []u16, cipher []u16) []u16 {
	mut x1 := idea_mul(cipher[0], idea_inverse(key[48])); mut x2 := sub16(cipher[2], key[50]); mut x3 := sub16(cipher[1], key[49]); mut x4 := idea_mul(cipher[3], idea_inverse(key[51]))
	for step := 7; step >= 0; step-- {
		k := step * 6
		p := idea_mul(x1 ^ x2, key[k + 4]); q := idea_mul(add16(x3 ^ x4, p), key[k + 5]); r := add16(p, q)
		a := x1 ^ q; c := x2 ^ q; b := x3 ^ r; d := x4 ^ r
		x1 = idea_mul(a, idea_inverse(key[k])); x2 = sub16(b, key[k + 1]); x3 = sub16(c, key[k + 2]); x4 = idea_mul(d, idea_inverse(key[k + 3]))
	}
	return [x1, x2, x3, x4]
}

@[export: 'idea_encrypt_decrypt']
pub fn idea_encrypt_decrypt(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length != 12 { return -1 }
	unsafe {
		mut key_words := []u16{len: 8, init: 0}
		mut plain_words := []u16{len: 4, init: 0}
		for i := 0; i < 12; i++ {
			value := input[i]
			if value < 0 || value > 65535 { return -1 }
			if i < 8 { key_words[i] = u16(value) } else { plain_words[i - 8] = u16(value) }
		}
		if output == nil || capacity < 16 { return -2 }
		keys := expand_key(key_words)
		encrypted := encrypt_block(keys, plain_words)
		recovered := decrypt_block(keys, encrypted)
		for i := 0; i < 4; i++ {
			output[i * 2] = u8(encrypted[i] & 255); output[i * 2 + 1] = u8(encrypted[i] >> 8)
			output[8 + i * 2] = u8(recovered[i] & 255); output[9 + i * 2] = u8(recovered[i] >> 8)
		}
		return 16
	}
}

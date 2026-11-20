module md4_digest

const r1 = [4]u32{3, 7, 11, 19}
const r2 = [4]u32{3, 5, 9, 13}
const r3 = [4]u32{3, 9, 11, 15}
const order3 = [16]int{0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15}

fn add32(left u32, right u32) u32 { return u32((u64(left) + u64(right)) & 0xffffffff) }
fn rotl32(value u32, amount u32) u32 { return (value << amount) | (value >> (32 - amount)) }
fn choose(x u32, y u32, z u32) u32 { return (x & y) | (~x & z) }
fn majority(x u32, y u32, z u32) u32 { return (x & y) | (x & z) | (y & z) }
fn parity(x u32, y u32, z u32) u32 { return x ^ y ^ z }

fn padded_word(input &i64, n int, padded int, bit_length u64, offset int, index int) u32 {
	mut result := u32(0)
	first := offset + index * 4
	unsafe {
		for byte in 0 .. 4 {
			position := first + byte
			mut part := u32(0)
			if position < n { part = u32(input[position + 1]) }
			else if position == n { part = 0x80 }
			else if position >= padded - 8 {
				part = u32((bit_length >> u64(8 * (position - (padded - 8)))) & 255)
			}
			result |= part << u32(8 * byte)
		}
	}
	return result
}

@[export: 'md4_digest']
pub fn md4_digest(input &i64, input_length usize, output &u8, capacity usize) i64 {
	if input_length < 1 || input_length > 4098 { return -1 }
	unsafe {
		if input == nil { return -1 }
		count := input[0]
		if count < 0 || count > 4096 || input_length != usize(count + 1) { return -1 }
		n := int(count)
		for i in 0 .. n { if input[i + 1] < 0 || input[i + 1] > 255 { return -1 } }
		if output == nil || capacity < 16 { return -2 }
		padded := ((n + 8) / 64 + 1) * 64
		bit_length := u64(n) * 8
		mut h0 := u32(0x67452301)
		mut h1 := u32(0xefcdab89)
		mut h2 := u32(0x98badcfe)
		mut h3 := u32(0x10325476)
		for offset := 0; offset < padded; offset += 64 {
			mut words := [16]u32{}
			for i in 0 .. 16 { words[i] = padded_word(input, n, padded, bit_length, offset, i) }
			mut a := h0
			mut b := h1
			mut c := h2
			mut d := h3
			for step in 0 .. 48 {
				round := step / 16
				j := step % 16
				mut mix := u32(0)
				mut word := 0
				mut shift := u32(0)
				mut constant := u32(0)
				if round == 0 { mix = choose(b, c, d); word = j; shift = r1[j % 4] }
				else if round == 1 {
					mix = majority(b, c, d); word = (j % 4) * 4 + j / 4
					shift = r2[j % 4]; constant = 0x5a827999
				} else { mix = parity(b, c, d); word = order3[j]; shift = r3[j % 4]; constant = 0x6ed9eba1 }
				next_b := add32(b, rotl32(add32(add32(add32(a, mix), words[word]), constant), shift))
				prior_d := d; d = c; c = b; b = next_b; a = prior_d
			}
			h0 = add32(h0, a); h1 = add32(h1, b); h2 = add32(h2, c); h3 = add32(h3, d)
		}
		state := [4]u32{h0, h1, h2, h3}
		for word in 0 .. 4 {
			for byte in 0 .. 4 { output[word * 4 + byte] = u8((state[word] >> u32(8 * byte)) & 255) }
		}
		return 16
	}
}

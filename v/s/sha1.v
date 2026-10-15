module sha1

const max_input = 4096
const max_padded = 4160

fn rol(value u32, shift u32) u32 { return (value << shift) | (value >> (32 - shift)) }
fn add32(left u32, right u32) u32 { return u32((u64(left) + u64(right)) & 0xffffffff) }

@[export: 'sha1']
pub fn sha1(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length > max_input || (length > 0 && unsafe { input == nil }) { return -1 }
	unsafe {
		for i in 0 .. length { if input[i] < 0 || input[i] > 255 { return -1 } }
		mut padded := [max_padded]u8{}
		for i in 0 .. length { padded[i] = u8(input[i]) }
		padded[length] = 0x80
		blocks := (length + 9 + 63) / 64
		padded_length := blocks * 64
		bit_length := u64(length) * 8
		for i in 0 .. 8 { padded[padded_length - 1 - i] = u8((bit_length >> (8 * i)) & 255) }
		mut h0 := u32(0x67452301); mut h1 := u32(0xEFCDAB89); mut h2 := u32(0x98BADCFE)
		mut h3 := u32(0x10325476); mut h4 := u32(0xC3D2E1F0)
		for block in 0 .. blocks {
			mut w := [80]u32{}
			for i in 0 .. 16 { p := block * 64 + i * 4; w[i] = (u32(padded[p]) << 24) | (u32(padded[p+1]) << 16) | (u32(padded[p+2]) << 8) | u32(padded[p+3]) }
			for i in 16 .. 80 { w[i] = rol(w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16], 1) }
			mut a := h0; mut b := h1; mut c := h2; mut d := h3; mut e := h4
			for i in 0 .. 80 {
				mut f := u32(0); mut k := u32(0)
				if i < 20 { f = (b & c) | ((~b) & d); k = 0x5A827999 }
				else if i < 40 { f = b ^ c ^ d; k = 0x6ED9EBA1 }
				else if i < 60 { f = (b & c) | (b & d) | (c & d); k = 0x8F1BBCDC }
				else { f = b ^ c ^ d; k = 0xCA62C1D6 }
				temp := add32(add32(add32(add32(rol(a, 5), f), e), k), w[i])
				e = d; d = c; c = rol(b, 30); b = a; a = temp
			}
			h0 = add32(h0, a); h1 = add32(h1, b); h2 = add32(h2, c); h3 = add32(h3, d); h4 = add32(h4, e)
		}
		if output == nil || capacity < 20 { return -2 }
		digest := [5]u32{h0,h1,h2,h3,h4}
		for i in 0 .. 5 { for byte in 0 .. 4 { output[i*4+byte] = u8((digest[i] >> (24 - 8 * byte)) & 255) } }
		return 20
	}
}

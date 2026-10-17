module poly1305

const max_message_length = 64
const max_input_length = 98
const limb_mask = u64(0x3ffffff)

fn load32_le(bytes &u8, offset int) u64 {
	unsafe {
		return u64(bytes[offset]) | (u64(bytes[offset + 1]) << 8) |
			(u64(bytes[offset + 2]) << 16) | (u64(bytes[offset + 3]) << 24)
	}
}

fn store32_le(mut output &u8, offset int, value u32) {
	for byte in 0 .. 4 { unsafe { output[offset + byte] = u8(value >> (8 * byte)) } }
}

fn poly1305_tag(key &u8, message &u8, message_length int, tag &u8) {
	unsafe {
		r0 := load32_le(key, 0) & 0x3ffffff
		r1 := (load32_le(key, 3) >> 2) & 0x3ffff03
		r2 := (load32_le(key, 6) >> 4) & 0x3ffc0ff
		r3 := (load32_le(key, 9) >> 6) & 0x3f03fff
		r4 := (load32_le(key, 12) >> 8) & 0x00fffff
		s1 := r1 * 5; s2 := r2 * 5; s3 := r3 * 5; s4 := r4 * 5
		mut h0 := u64(0); mut h1 := u64(0); mut h2 := u64(0); mut h3 := u64(0); mut h4 := u64(0)
		mut offset := 0
		for offset < message_length {
			mut block := [16]u8{}
			block_length := min(16, message_length - offset)
			for i in 0 .. block_length { block[i] = message[offset + i] }
			mut high_bit := u64(1) << 24
			if block_length < 16 { block[block_length] = 1; high_bit = 0 }
			h0 += load32_le(&block[0], 0) & limb_mask
			h1 += (load32_le(&block[0], 3) >> 2) & limb_mask
			h2 += (load32_le(&block[0], 6) >> 4) & limb_mask
			h3 += (load32_le(&block[0], 9) >> 6) & limb_mask
			h4 += (load32_le(&block[0], 12) >> 8) | high_bit
			d0 := h0 * r0 + h1 * s4 + h2 * s3 + h3 * s2 + h4 * s1
			d1 := h0 * r1 + h1 * r0 + h2 * s4 + h3 * s3 + h4 * s2
			d2 := h0 * r2 + h1 * r1 + h2 * r0 + h3 * s4 + h4 * s3
			d3 := h0 * r3 + h1 * r2 + h2 * r1 + h3 * r0 + h4 * s4
			d4 := h0 * r4 + h1 * r3 + h2 * r2 + h3 * r1 + h4 * r0
			mut carry := d0 >> 26; h0 = d0 & limb_mask
			q1 := d1 + carry; carry = q1 >> 26; h1 = q1 & limb_mask
			q2 := d2 + carry; carry = q2 >> 26; h2 = q2 & limb_mask
			q3 := d3 + carry; carry = q3 >> 26; h3 = q3 & limb_mask
			q4 := d4 + carry; carry = q4 >> 26; h4 = q4 & limb_mask
			h0 += carry * 5
			carry = h0 >> 26; h0 &= limb_mask; h1 += carry
			offset += block_length
		}
		for _ in 0 .. 3 {
			mut carry := h0 >> 26; h0 &= limb_mask; h1 += carry
			carry = h1 >> 26; h1 &= limb_mask; h2 += carry
			carry = h2 >> 26; h2 &= limb_mask; h3 += carry
			carry = h3 >> 26; h3 &= limb_mask; h4 += carry
			carry = h4 >> 26; h4 &= limb_mask; h0 += carry * 5
			carry = h0 >> 26; h0 &= limb_mask; h1 += carry
		}
		if h4 == limb_mask && h3 == limb_mask && h2 == limb_mask && h1 == limb_mask && h0 >= limb_mask - 4 {
			h0 -= limb_mask - 4; h1 = 0; h2 = 0; h3 = 0; h4 = 0
		}
		f0 := ((h0 | (h1 << 26)) & 0xffffffff) + load32_le(key, 16)
		f1 := ((h1 >> 6 | (h2 << 20)) & 0xffffffff) + load32_le(key, 20) + (f0 >> 32)
		f2 := ((h2 >> 12 | (h3 << 14)) & 0xffffffff) + load32_le(key, 24) + (f1 >> 32)
		f3 := ((h3 >> 18 | (h4 << 8)) & 0xffffffff) + load32_le(key, 28) + (f2 >> 32)
		store32_le(mut tag, 0, u32(f0)); store32_le(mut tag, 4, u32(f1))
		store32_le(mut tag, 8, u32(f2)); store32_le(mut tag, 12, u32(f3))
	}
}

@[export: 'poly1305']
pub fn poly1305(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 33 || length > usize(max_input_length) { return -1 }
		raw_length := input[0]
		if raw_length < 0 || raw_length > max_message_length || int(length) != 33 + int(raw_length) { return -1 }
		for i in 1 .. int(length) { if input[i] < 0 || input[i] > 255 { return -1 } }
		if output == nil || output_capacity < 16 { return -2 }
		mut key := [32]u8{}
		mut message := [max_message_length]u8{}
		mut tag := [16]u8{}
		for i in 0 .. 32 { key[i] = u8(input[1 + i]) }
		for i in 0 .. int(raw_length) { message[i] = u8(input[33 + i]) }
		poly1305_tag(&key[0], &message[0], int(raw_length), &tag[0])
		for i in 0 .. 16 { output[i] = tag[i] }
		return 16
	}
}

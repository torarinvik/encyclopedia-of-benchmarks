package poly1305

MAX_MESSAGE_LENGTH :: 64
MAX_INPUT_LENGTH :: 98
LIMB_MASK :: u64(0x3ffffff)

load32_le :: proc "contextless" (bytes: [^]u8, offset: int) -> u64 {
	return u64(bytes[offset]) | (u64(bytes[offset + 1]) << 8) |
		(u64(bytes[offset + 2]) << 16) | (u64(bytes[offset + 3]) << 24)
}

store32_le :: proc "contextless" (output: [^]u8, offset: int, value: u32) {
	for byte := 0; byte < 4; byte += 1 do output[offset + byte] = u8(value >> (8 * byte))
}

poly1305_tag :: proc "contextless" (key, message, tag: [^]u8, message_length: int) {
	r0 := load32_le(key, 0) & 0x3ffffff
	r1 := (load32_le(key, 3) >> 2) & 0x3ffff03
	r2 := (load32_le(key, 6) >> 4) & 0x3ffc0ff
	r3 := (load32_le(key, 9) >> 6) & 0x3f03fff
	r4 := (load32_le(key, 12) >> 8) & 0x00fffff
	s1, s2, s3, s4 := r1 * 5, r2 * 5, r3 * 5, r4 * 5
	h0, h1, h2, h3, h4: u64 = 0, 0, 0, 0, 0
	offset := 0
	for offset < message_length {
		block: [16]u8
		block_length := message_length - offset
		if block_length > 16 do block_length = 16
		for i := 0; i < block_length; i += 1 do block[i] = message[offset + i]
		high_bit := u64(1) << 24
		if block_length < 16 { block[block_length] = 1; high_bit = 0 }
		h0 += load32_le(&block[0], 0) & LIMB_MASK
		h1 += (load32_le(&block[0], 3) >> 2) & LIMB_MASK
		h2 += (load32_le(&block[0], 6) >> 4) & LIMB_MASK
		h3 += (load32_le(&block[0], 9) >> 6) & LIMB_MASK
		h4 += (load32_le(&block[0], 12) >> 8) | high_bit
		d0 := h0*r0 + h1*s4 + h2*s3 + h3*s2 + h4*s1
		d1 := h0*r1 + h1*r0 + h2*s4 + h3*s3 + h4*s2
		d2 := h0*r2 + h1*r1 + h2*r0 + h3*s4 + h4*s3
		d3 := h0*r3 + h1*r2 + h2*r1 + h3*r0 + h4*s4
		d4 := h0*r4 + h1*r3 + h2*r2 + h3*r1 + h4*r0
		carry := d0 >> 26; h0 = d0 & LIMB_MASK
		q1 := d1 + carry; carry = q1 >> 26; h1 = q1 & LIMB_MASK
		q2 := d2 + carry; carry = q2 >> 26; h2 = q2 & LIMB_MASK
		q3 := d3 + carry; carry = q3 >> 26; h3 = q3 & LIMB_MASK
		q4 := d4 + carry; carry = q4 >> 26; h4 = q4 & LIMB_MASK
		h0 += carry * 5
		carry = h0 >> 26; h0 &= LIMB_MASK; h1 += carry
		offset += block_length
	}
	for pass := 0; pass < 3; pass += 1 {
		carry := h0 >> 26; h0 &= LIMB_MASK; h1 += carry
		carry = h1 >> 26; h1 &= LIMB_MASK; h2 += carry
		carry = h2 >> 26; h2 &= LIMB_MASK; h3 += carry
		carry = h3 >> 26; h3 &= LIMB_MASK; h4 += carry
		carry = h4 >> 26; h4 &= LIMB_MASK; h0 += carry * 5
		carry = h0 >> 26; h0 &= LIMB_MASK; h1 += carry
	}
	if h4 == LIMB_MASK && h3 == LIMB_MASK && h2 == LIMB_MASK && h1 == LIMB_MASK && h0 >= LIMB_MASK - 4 {
		h0 -= LIMB_MASK - 4; h1, h2, h3, h4 = 0, 0, 0, 0
	}
	f0 := ((h0 | (h1 << 26)) & 0xffffffff) + load32_le(key, 16)
	f1 := ((h1 >> 6 | (h2 << 20)) & 0xffffffff) + load32_le(key, 20) + (f0 >> 32)
	f2 := ((h2 >> 12 | (h3 << 14)) & 0xffffffff) + load32_le(key, 24) + (f1 >> 32)
	f3 := ((h3 >> 18 | (h4 << 8)) & 0xffffffff) + load32_le(key, 28) + (f2 >> 32)
	store32_le(tag, 0, u32(f0)); store32_le(tag, 4, u32(f1))
	store32_le(tag, 8, u32(f2)); store32_le(tag, 12, u32(f3))
}

@(export)
poly1305 :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 33 || length > MAX_INPUT_LENGTH do return -1
	raw_length := input[0]
	if raw_length < 0 || raw_length > MAX_MESSAGE_LENGTH || int(length) != 33 + int(raw_length) do return -1
	for i := 1; i < int(length); i += 1 do if input[i] < 0 || input[i] > 255 do return -1
	if output == nil || int(output_capacity) < 16 do return -2
	key: [32]u8
	message: [MAX_MESSAGE_LENGTH]u8
	tag: [16]u8
	for i := 0; i < 32; i += 1 do key[i] = u8(input[1 + i])
	for i := 0; i < int(raw_length); i += 1 do message[i] = u8(input[33 + i])
	poly1305_tag(&key[0], &message[0], &tag[0], int(raw_length))
	for i := 0; i < 16; i += 1 do output[i] = tag[i]
	return 16
}

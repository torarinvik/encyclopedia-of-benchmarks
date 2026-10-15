package a5_cipher

import "core:c"

State :: struct { r1, r2, r3: u32 }

parity :: proc "contextless" (value: u32) -> u32 {
	x := value
	x ~= x >> 16; x ~= x >> 8; x ~= x >> 4; x ~= x >> 2; x ~= x >> 1
	return x & 1
}
fb1 :: proc "contextless" (s: State) -> u32 { return parity(s.r1 & ((1<<13)|(1<<16)|(1<<17)|(1<<18))) }
fb2 :: proc "contextless" (s: State) -> u32 { return parity(s.r2 & ((1<<20)|(1<<21))) }
fb3 :: proc "contextless" (s: State) -> u32 { return parity(s.r3 & ((1<<7)|(1<<20)|(1<<21)|(1<<22))) }
push :: proc "contextless" (register: u32, width: u32, bit: u32) -> u32 { return ((register << 1) | bit) & ((u32(1) << width) - 1) }

initialize :: proc "contextless" (key: u64, frame: u32) -> State {
	s := State{}
	for n := 0; n < 64; n += 1 {
		i := 63 - n
		bit := u32((key >> u64(i)) & 1)
		s.r1 = push(s.r1, 19, bit ~ fb1(s)); s.r2 = push(s.r2, 22, bit ~ fb2(s)); s.r3 = push(s.r3, 23, bit ~ fb3(s))
	}
	for n := 0; n < 22; n += 1 {
		i := 21 - n
		bit := (frame >> u32(i)) & 1
		s.r1 = push(s.r1, 19, bit ~ fb1(s)); s.r2 = push(s.r2, 22, bit ~ fb2(s)); s.r3 = push(s.r3, 23, bit ~ fb3(s))
	}
	return s
}

tick :: proc "contextless" (s: ^State) -> u32 {
	c1 := (s.r1 >> 8) & 1; c2 := (s.r2 >> 10) & 1; c3 := (s.r3 >> 10) & 1
	majority: u32 = 0
	if c1 + c2 + c3 >= 2 { majority = 1 }
	result := ((s.r1 >> 18) ~ (s.r2 >> 21) ~ (s.r3 >> 22)) & 1
	if c1 == majority { s.r1 = push(s.r1, 19, fb1(s^)) }
	if c2 == majority { s.r2 = push(s.r2, 22, fb2(s^)) }
	if c3 == majority { s.r3 = push(s.r3, 23, fb3(s^)) }
	return result
}

next_frame :: proc "contextless" (frame_input: u32) -> u32 {
	frame := frame_input
	for n := 0; n < 22; n += 1 {
		i := 21 - n; mask := u32(1) << u32(i)
		if frame & mask == 0 { return frame | mask }
		frame &= ~mask
	}
	return frame
}

store_bit :: proc "contextless" (output: [^]u8, block_offset, bit: int, value: u32) {
	output[block_offset + bit / 8] |= u8(value << u32(bit % 8))
}

@(export)
a5_cipher :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 do return -1
	if input[2] < 1 || input[2] > 4 do return -1
	blocks := int(input[2])
	if length != c.size_t(3 + 4 * blocks) do return -1
	byte_count := blocks * 32
	if output == nil || output_capacity < c.size_t(byte_count) do return -2
	key := u64(input[0]); frame := u32(u64(input[1]) & 0x3fffff)
	for block := 0; block < blocks; block += 1 {
		s := initialize(key, frame)
		cycle := 0
		for cycle < 100 {
			_ = tick(&s)
			cycle += 1
		}
		for i := 0; i < 32; i += 1 { output[block * 32 + i] = 0 }
		for bit := 0; bit < 228; bit += 1 {
			plain := u64(input[3 + 4 * block + bit / 64])
			value := u32((plain >> u64(bit % 64)) & 1) ~ tick(&s)
			store_bit(output, block * 32, bit, value)
		}
		for bit := 228; bit < 256; bit += 1 {
			plain := u64(input[3 + 4 * block + bit / 64])
			value := u32((plain >> u64(bit % 64)) & 1)
			store_bit(output, block * 32, bit, value)
		}
		frame = next_frame(frame)
	}
	return i64(byte_count)
}

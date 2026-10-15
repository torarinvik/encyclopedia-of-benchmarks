module a5_cipher

struct State { r1 u32; r2 u32; r3 u32 }

fn parity(value u32) u32 {
	mut x := value
	x ^= x >> 16; x ^= x >> 8; x ^= x >> 4; x ^= x >> 2; x ^= x >> 1
	return x & 1
}
fn fb1(s State) u32 { return parity(s.r1 & ((u32(1)<<13)|(u32(1)<<16)|(u32(1)<<17)|(u32(1)<<18))) }
fn fb2(s State) u32 { return parity(s.r2 & ((u32(1)<<20)|(u32(1)<<21))) }
fn fb3(s State) u32 { return parity(s.r3 & ((u32(1)<<7)|(u32(1)<<20)|(u32(1)<<21)|(u32(1)<<22))) }
fn push(register u32, width u32, bit u32) u32 { return ((register << 1) | bit) & ((u32(1) << width) - 1) }

fn initialize(key u64, frame u32) State {
	mut s := State{}
	for n in 0 .. 64 {
		i := 63 - n
		bit := u32((key >> u32(i)) & 1)
		s.r1 = push(s.r1, 19, bit ^ fb1(s)); s.r2 = push(s.r2, 22, bit ^ fb2(s)); s.r3 = push(s.r3, 23, bit ^ fb3(s))
	}
	for n in 0 .. 22 {
		i := 21 - n
		bit := (frame >> u32(i)) & 1
		s.r1 = push(s.r1, 19, bit ^ fb1(s)); s.r2 = push(s.r2, 22, bit ^ fb2(s)); s.r3 = push(s.r3, 23, bit ^ fb3(s))
	}
	return s
}

fn tick(mut s State) u32 {
	c1 := (s.r1 >> 8) & 1; c2 := (s.r2 >> 10) & 1; c3 := (s.r3 >> 10) & 1
	mut majority := u32(0)
	if c1 + c2 + c3 >= 2 { majority = 1 }
	result := ((s.r1 >> 18) ^ (s.r2 >> 21) ^ (s.r3 >> 22)) & 1
	if c1 == majority { s.r1 = push(s.r1, 19, fb1(s)) }
	if c2 == majority { s.r2 = push(s.r2, 22, fb2(s)) }
	if c3 == majority { s.r3 = push(s.r3, 23, fb3(s)) }
	return result
}

fn next_frame(mut frame u32) u32 {
	for n in 0 .. 22 {
		i := 21 - n; mask := u32(1) << u32(i)
		if frame & mask == 0 { return frame | mask }
		frame &= ~mask
	}
	return frame
}

fn store_bit(mut output &u8, offset int, bit int, value u8) {
	unsafe { output[offset + bit / 8] |= value << u32(bit % 8) }
}

@[export: 'a5_cipher']
pub fn a5_cipher(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 3 || unsafe { input == nil } { return -1 }
	unsafe {
		if input[2] < 1 || input[2] > 4 { return -1 }
		blocks := int(input[2]); if length != usize(3 + 4 * blocks) { return -1 }
		byte_count := blocks * 32
		if output == nil || output_capacity < usize(byte_count) { return -2 }
		key := u64(input[0]); mut frame := u32(u64(input[1]) & 0x3fffff)
		for block in 0 .. blocks {
			mut s := initialize(key, frame)
			for _ in 0 .. 100 { _ = tick(mut s) }
			for i in 0 .. 32 { output[block * 32 + i] = 0 }
			for bit in 0 .. 228 {
				plain := u64(input[3 + 4 * block + bit / 64]); value := u8((plain >> u32(bit % 64)) & 1) ^ u8(tick(mut s))
				store_bit(mut output, block * 32, bit, value)
			}
			for bit in 228 .. 256 {
				plain := u64(input[3 + 4 * block + bit / 64]); value := u8((plain >> u32(bit % 64)) & 1)
				store_bit(mut output, block * 32, bit, value)
			}
			frame = next_frame(mut frame)
		}
		return i64(byte_count)
	}
}

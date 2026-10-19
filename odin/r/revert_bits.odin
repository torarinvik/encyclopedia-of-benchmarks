package revert_bits

import "core:c"

OUTPUT_BYTES :: 12

reverse_bits32 :: proc(n0: u32) -> u32 {
	n := n0
	n = ((n >> 1) & u32(0x55555555)) | ((n & u32(0x55555555)) << 1)
	n = ((n >> 2) & u32(0x33333333)) | ((n & u32(0x33333333)) << 2)
	n = ((n >> 4) & u32(0x0f0f0f0f)) | ((n & u32(0x0f0f0f0f)) << 4)
	return ((n & u32(0xff000000)) >> 24) | ((n & u32(0x00ff0000)) >> 8) |
	       ((n & u32(0x0000ff00)) << 8) | ((n & u32(0x000000ff)) << 24)
}

reverse_bits64 :: proc(n0: u64) -> u64 {
	n := n0
	n = ((n >> 1) & u64(0x5555555555555555)) | ((n & u64(0x5555555555555555)) << 1)
	n = ((n >> 2) & u64(0x3333333333333333)) | ((n & u64(0x3333333333333333)) << 2)
	n = ((n >> 4) & u64(0x0f0f0f0f0f0f0f0f)) | ((n & u64(0x0f0f0f0f0f0f0f0f)) << 4)
	return ((n & u64(0xff00000000000000)) >> 56) |
	       ((n & u64(0x00ff000000000000)) >> 40) |
	       ((n & u64(0x0000ff0000000000)) >> 24) |
	       ((n & u64(0x000000ff00000000)) >> 8) |
	       ((n & u64(0x00000000ff000000)) << 8) |
	       ((n & u64(0x0000000000ff0000)) << 24) |
	       ((n & u64(0x000000000000ff00)) << 40) |
	       ((n & u64(0x00000000000000ff)) << 56)
}

@(export)
revert_bits :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 2 || input[0] < 0 || input[0] > 4_294_967_295 do return -1
	if output == nil || capacity < OUTPUT_BYTES do return -2
	reversed32 := reverse_bits32(u32(input[0]))
	reversed64 := reverse_bits64(transmute(u64)input[1])
	for i := 0; i < 4; i += 1 { output[i] = u8(reversed32 >> u32(8*i)) }
	for i := 0; i < 8; i += 1 { output[4+i] = u8(reversed64 >> u64(8*i)) }
	return OUTPUT_BYTES
}

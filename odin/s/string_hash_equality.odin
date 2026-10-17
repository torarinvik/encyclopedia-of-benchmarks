package string_hash_equality

import "core:c"

ROUND_CONSTANTS :: [24]u64{0x0000000000000001,
	0x0000000000008082,
	0x800000000000808a,
	0x8000000080008000,
	0x000000000000808b,
	0x0000000080000001,
	0x8000000080008081,
	0x8000000000008009,
	0x000000000000008a,
	0x0000000000000088,
	0x0000000080008009,
	0x000000008000000a,
	0x000000008000808b,
	0x800000000000008b,
	0x8000000000008089,
	0x8000000000008003,
	0x8000000000008002,
	0x8000000000000080,
	0x000000000000800a,
	0x800000008000000a,
	0x8000000080008081,
	0x8000000000008080,
	0x0000000080000001,
	0x8000000080008008}
ROTATION_OFFSETS :: [25]int{0, 1, 62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43, 25, 39, 41, 45, 15, 21, 8, 18, 2, 61, 56, 14}

rotate_left :: proc "contextless" (value: u64, amount: int) -> u64 {
    if amount == 0 do return value
    return (value << u32(amount)) | (value >> u32(64 - amount))
}

keccak_f1600 :: proc "contextless" (state: ^[25]u64) {
    for round := 0; round < 24; round += 1 {
        column: [5]u64
        delta: [5]u64
        moved: [25]u64
        for x := 0; x < 5; x += 1 do column[x] = state[x] ~ state[x + 5] ~ state[x + 10] ~ state[x + 15] ~ state[x + 20]
        for x := 0; x < 5; x += 1 do delta[x] = column[(x + 4) % 5] ~ rotate_left(column[(x + 1) % 5], 1)
        for y := 0; y < 5; y += 1 {
            for x := 0; x < 5; x += 1 {
                source := x + 5 * y
                target := y + 5 * ((2 * x + 3 * y) % 5)
                moved[target] = rotate_left(state[source] ~ delta[x], ROTATION_OFFSETS[source])
            }
        }
        for y := 0; y < 5; y += 1 {
            for x := 0; x < 5; x += 1 {
                state[x + 5 * y] = moved[x + 5 * y] ~ ((~moved[(x + 1) % 5 + 5 * y]) & moved[(x + 2) % 5 + 5 * y])
            }
        }
        state[0] ~= ROUND_CONSTANTS[round]
    }
}

keccak256_bytes :: proc "contextless" (input: [^]i64, start, byte_length: int, digest: ^[4]u64) {
    block: [136]u8
    for i := 0; i < byte_length; i += 1 do block[i] = u8(input[start + i])
    block[byte_length] ~= 0x01
    block[135] ~= 0x80
    state: [25]u64
    for lane := 0; lane < 17; lane += 1 {
        for byte := 0; byte < 8; byte += 1 {
            state[lane] |= u64(block[lane * 8 + byte]) << u32(8 * byte)
        }
    }
    keccak_f1600(&state)
    for lane := 0; lane < 4; lane += 1 do digest[lane] = state[lane]
}

@(export)
string_hash_equality :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 131 do return -1
    if input[0] < 0 || input[0] > 64 || input[1] < 0 || input[1] > 64 do return -1
    length_a, length_b := int(input[0]), int(input[1])
    if int(length) != 2 + length_a + length_b do return -1
    for i := 0; i < length_a + length_b; i += 1 do if input[2 + i] < 0 || input[2 + i] > 255 do return -1
    digest_a: [4]u64
    digest_b: [4]u64
    keccak256_bytes(input, 2, length_a, &digest_a)
    keccak256_bytes(input, 2 + length_a, length_b, &digest_b)
    for lane := 0; lane < 4; lane += 1 do if digest_a[lane] != digest_b[lane] do return 0
    return 1
}

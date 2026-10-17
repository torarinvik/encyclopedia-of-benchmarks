module string_hash_equality

const round_constants = [24]u64{
    u64(0x0000000000000001),
	u64(0x0000000000008082),
	u64(0x800000000000808a),
	u64(0x8000000080008000),
	u64(0x000000000000808b),
	u64(0x0000000080000001),
	u64(0x8000000080008081),
	u64(0x8000000000008009),
	u64(0x000000000000008a),
	u64(0x0000000000000088),
	u64(0x0000000080008009),
	u64(0x000000008000000a),
	u64(0x000000008000808b),
	u64(0x800000000000008b),
	u64(0x8000000000008089),
	u64(0x8000000000008003),
	u64(0x8000000000008002),
	u64(0x8000000000000080),
	u64(0x000000000000800a),
	u64(0x800000008000000a),
	u64(0x8000000080008081),
	u64(0x8000000000008080),
	u64(0x0000000080000001),
	u64(0x8000000080008008)
}
const rotation_offsets = [25]int{0, 1, 62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43, 25, 39, 41, 45, 15, 21, 8, 18, 2, 61, 56, 14}

fn keccak_rotate_left(value u64, amount int) u64 {
    if amount == 0 { return value }
    return (value << amount) | (value >> (64 - amount))
}

fn keccak_f1600(mut state [25]u64) {
    for round in 0 .. 24 {
        mut column := [5]u64{}
        mut delta := [5]u64{}
        mut moved := [25]u64{}
        for x in 0 .. 5 { column[x] = state[x] ^ state[x + 5] ^ state[x + 10] ^ state[x + 15] ^ state[x + 20] }
        for x in 0 .. 5 { delta[x] = column[(x + 4) % 5] ^ keccak_rotate_left(column[(x + 1) % 5], 1) }
        for y in 0 .. 5 {
            for x in 0 .. 5 {
                source := x + 5 * y
                target := y + 5 * ((2 * x + 3 * y) % 5)
                moved[target] = keccak_rotate_left(state[source] ^ delta[x], rotation_offsets[source])
            }
        }
        for y in 0 .. 5 {
            for x in 0 .. 5 {
                state[x + 5 * y] = moved[x + 5 * y] ^ ((~moved[(x + 1) % 5 + 5 * y]) & moved[(x + 2) % 5 + 5 * y])
            }
        }
        state[0] ^= round_constants[round]
    }
}

fn keccak256_bytes(input &i64, start int, byte_length int, mut digest [4]u64) {
    mut block := [136]u8{}
    unsafe {
        for i in 0 .. byte_length { block[i] = u8(input[start + i]) }
    }
    block[byte_length] ^= 0x01
    block[135] ^= 0x80
    mut state := [25]u64{}
    for lane in 0 .. 17 {
        for byte in 0 .. 8 { state[lane] |= u64(block[lane * 8 + byte]) << (8 * byte) }
    }
    keccak_f1600(mut state)
    for lane in 0 .. 4 { digest[lane] = state[lane] }
}

@[export: 'string_hash_equality']
pub fn string_hash_equality(input &i64, length usize) i64 {
    if length < 2 || length > 131 || unsafe { input == nil } { return -1 }
    unsafe {
        if input[0] < 0 || input[0] > 64 || input[1] < 0 || input[1] > 64 { return -1 }
        length_a := int(input[0]); length_b := int(input[1])
        if int(length) != 2 + length_a + length_b { return -1 }
        for i in 0 .. length_a + length_b { if input[2 + i] < 0 || input[2 + i] > 255 { return -1 } }
        mut digest_a := [4]u64{}
        mut digest_b := [4]u64{}
        keccak256_bytes(input, 2, length_a, mut digest_a)
        keccak256_bytes(input, 2 + length_a, length_b, mut digest_b)
        for lane in 0 .. 4 { if digest_a[lane] != digest_b[lane] { return 0 } }
        return 1
    }
}

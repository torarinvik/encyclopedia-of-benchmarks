const MAX_BYTES: i64 = 64;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 131;
const RATE_BYTES: usize = 136;
const ROUND_CONSTANTS: [u64; 24] = [
    0x0000000000000001,
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
    0x8000000080008008
];
const ROTATION_OFFSETS: [u32; 25] = [0, 1, 62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43, 25, 39, 41, 45, 15, 21, 8, 18, 2, 61, 56, 14];

fn keccak_f1600(state: &mut [u64; 25]) {
    for round in 0..24 {
        let mut column = [0u64; 5];
        let mut delta = [0u64; 5];
        for x in 0..5 { column[x] = state[x] ^ state[x + 5] ^ state[x + 10] ^ state[x + 15] ^ state[x + 20]; }
        for x in 0..5 { delta[x] = column[(x + 4) % 5] ^ column[(x + 1) % 5].rotate_left(1); }
        let mut moved = [0u64; 25];
        for y in 0..5 {
            for x in 0..5 {
                let source = x + 5 * y;
                let target = y + 5 * ((2 * x + 3 * y) % 5);
                moved[target] = (state[source] ^ delta[x]).rotate_left(ROTATION_OFFSETS[source]);
            }
        }
        for y in 0..5 {
            for x in 0..5 {
                state[x + 5 * y] = moved[x + 5 * y] ^ ((!moved[(x + 1) % 5 + 5 * y]) & moved[(x + 2) % 5 + 5 * y]);
            }
        }
        state[0] ^= ROUND_CONSTANTS[round];
    }
}

fn keccak256_bytes(input: &[i64], start: usize, byte_length: usize) -> [u64; 4] {
    let mut block = [0u8; RATE_BYTES];
    for i in 0..byte_length { block[i] = input[start + i] as u8; }
    block[byte_length] ^= 0x01;
    block[RATE_BYTES - 1] ^= 0x80;
    let mut state = [0u64; 25];
    for lane in 0..RATE_BYTES / 8 {
        for byte in 0..8 { state[lane] |= (block[lane * 8 + byte] as u64) << (8 * byte); }
    }
    keccak_f1600(&mut state);
    [state[0], state[1], state[2], state[3]]
}

#[no_mangle]
pub unsafe extern "C" fn string_hash_equality(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_BYTES).contains(&values[0]) || !(0..=MAX_BYTES).contains(&values[1]) { return -1; }
    let (length_a, length_b) = (values[0] as usize, values[1] as usize);
    if length != 2 + length_a + length_b { return -1; }
    if values[2..].iter().any(|&byte| !(0..=255).contains(&byte)) { return -1; }
    let digest_a = keccak256_bytes(values, 2, length_a);
    let digest_b = keccak256_bytes(values, 2 + length_a, length_b);
    if digest_a == digest_b { 1 } else { 0 }
}

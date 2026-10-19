const KEY_BYTES: usize = 32;
const BLOCK_BYTES: usize = 16;
const INPUT_BYTES: usize = KEY_BYTES + BLOCK_BYTES;

fn gf_mul(mut left: u8, mut right: u8) -> u8 {
    let mut result = 0u8;
    while right != 0 {
        if right & 1 != 0 { result ^= left; }
        left = (left << 1) ^ if left & 0x80 != 0 { 0x1b } else { 0 };
        right >>= 1;
    }
    result
}

fn gf_pow(mut value: u8, mut exponent: u32) -> u8 {
    let mut result = 1u8;
    while exponent != 0 {
        if exponent & 1 != 0 { result = gf_mul(result, value); }
        value = gf_mul(value, value);
        exponent >>= 1;
    }
    result
}

fn make_sbox() -> [u8; 256] {
    let mut sbox = [0u8; 256];
    for value in 0..256 {
        let inverse = if value == 0 { 0 } else { gf_pow(value as u8, 254) };
        sbox[value] = inverse ^ inverse.rotate_left(1) ^ inverse.rotate_left(2)
            ^ inverse.rotate_left(3) ^ inverse.rotate_left(4) ^ 0x63;
    }
    sbox
}

fn encrypt_block(key: &[u8; KEY_BYTES], block: &[u8; BLOCK_BYTES]) -> [u8; BLOCK_BYTES] {
    let sbox = make_sbox();
    let round_constants = [1u8, 2, 4, 8, 16, 32, 64];
    let mut round_keys = [0u8; 240];
    round_keys[..KEY_BYTES].copy_from_slice(key);
    let mut written = KEY_BYTES;
    while written < round_keys.len() {
        let word = written / 4;
        let mut temporary = [round_keys[written - 4], round_keys[written - 3],
            round_keys[written - 2], round_keys[written - 1]];
        if word % 8 == 0 {
            temporary.rotate_left(1);
            for byte in &mut temporary { *byte = sbox[*byte as usize]; }
            temporary[0] ^= round_constants[word / 8 - 1];
        } else if word % 8 == 4 {
            for byte in &mut temporary { *byte = sbox[*byte as usize]; }
        }
        for byte in temporary {
            round_keys[written] = round_keys[written - KEY_BYTES] ^ byte;
            written += 1;
        }
    }

    let mut state = *block;
    for index in 0..BLOCK_BYTES { state[index] ^= round_keys[index]; }
    for round in 1..14 {
        for byte in &mut state { *byte = sbox[*byte as usize]; }
        let previous = state;
        for column in 0..4 {
            for row in 0..4 {
                state[row + 4 * column] = previous[row + 4 * ((column + row) % 4)];
            }
        }
        for column in 0..4 {
            let offset = 4 * column;
            let a = state[offset];
            let b = state[offset + 1];
            let c = state[offset + 2];
            let d = state[offset + 3];
            let total = a ^ b ^ c ^ d;
            state[offset] = a ^ total ^ gf_mul(a ^ b, 2);
            state[offset + 1] = b ^ total ^ gf_mul(b ^ c, 2);
            state[offset + 2] = c ^ total ^ gf_mul(c ^ d, 2);
            state[offset + 3] = d ^ total ^ gf_mul(d ^ a, 2);
        }
        let key_offset = round * BLOCK_BYTES;
        for index in 0..BLOCK_BYTES { state[index] ^= round_keys[key_offset + index]; }
    }
    for byte in &mut state { *byte = sbox[*byte as usize]; }
    let previous = state;
    for column in 0..4 {
        for row in 0..4 {
            state[row + 4 * column] = previous[row + 4 * ((column + row) % 4)];
        }
    }
    for index in 0..BLOCK_BYTES { state[index] ^= round_keys[224 + index]; }
    state
}

#[no_mangle]
pub unsafe extern "C" fn mibench_security_rijndael(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length != INPUT_BYTES { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if values.iter().any(|value| *value < 0 || *value > 255) { return -1; }
    if output.is_null() || output_capacity < BLOCK_BYTES { return -2; }
    let mut key = [0u8; KEY_BYTES];
    let mut block = [0u8; BLOCK_BYTES];
    for index in 0..KEY_BYTES { key[index] = values[index] as u8; }
    for index in 0..BLOCK_BYTES { block[index] = values[KEY_BYTES + index] as u8; }
    let ciphertext = encrypt_block(&key, &block);
    std::slice::from_raw_parts_mut(output, BLOCK_BYTES).copy_from_slice(&ciphertext);
    BLOCK_BYTES as i64
}

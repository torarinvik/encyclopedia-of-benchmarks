const MAX_MESSAGE_BYTES: usize = 4096;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 4099;
const MAX_OUTPUT_BYTES: usize = 64;
const ROUND_CONSTANTS: [u64; 24] = [
    0x0000000000000001, 0x0000000000008082, 0x800000000000808a, 0x8000000080008000,
    0x000000000000808b, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
    0x000000000000008a, 0x0000000000000088, 0x0000000080008009, 0x000000008000000a,
    0x000000008000808b, 0x800000000000008b, 0x8000000000008089, 0x8000000000008003,
    0x8000000000008002, 0x8000000000000080, 0x000000000000800a, 0x800000008000000a,
    0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008,
];
const ROTATION_OFFSETS: [u32; 25] = [
    0, 1, 62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43,
    25, 39, 41, 45, 15, 21, 8, 18, 2, 61, 56, 14,
];

fn keccak_f(state: &mut [u64; 25]) {
    for round_constant in ROUND_CONSTANTS {
        let mut column = [0u64; 5];
        let mut delta = [0u64; 5];
        let mut moved = [0u64; 25];
        for x in 0..5 {
            column[x] = state[x] ^ state[x + 5] ^ state[x + 10] ^ state[x + 15] ^ state[x + 20];
        }
        for x in 0..5 {
            delta[x] = column[(x + 4) % 5] ^ column[(x + 1) % 5].rotate_left(1);
        }
        for y in 0..5 {
            for x in 0..5 {
                state[x + 5 * y] ^= delta[x];
            }
        }

        for y in 0..5 {
            for x in 0..5 {
                let source = x + 5 * y;
                let target = y + 5 * ((2 * x + 3 * y) % 5);
                moved[target] = state[source].rotate_left(ROTATION_OFFSETS[source]);
            }
        }
        for y in 0..5 {
            for x in 0..5 {
                state[x + 5 * y] = moved[x + 5 * y]
                    ^ ((!moved[(x + 1) % 5 + 5 * y]) & moved[(x + 2) % 5 + 5 * y]);
            }
        }
        state[0] ^= round_constant;
    }
}

fn absorb_byte(state: &mut [u64; 25], offset: usize, value: u8) {
    state[offset / 8] ^= (value as u64) << ((offset % 8) * 8);
}

fn sha3_digest(variant: usize, values: &[i64]) -> [u8; 64] {
    let digest_lengths = [28usize, 32, 48, 64];
    let rates = [144usize, 136, 104, 72];
    let message_length = values[1] as usize;
    let rate = rates[variant];
    let mut state = [0u64; 25];
    let mut offset = 0;
    while message_length - offset >= rate {
        for index in 0..rate {
            absorb_byte(&mut state, index, values[2 + offset + index] as u8);
        }
        keccak_f(&mut state);
        offset += rate;
    }

    let mut block = [0u8; 144];
    let remaining = message_length - offset;
    for index in 0..remaining {
        block[index] = values[2 + offset + index] as u8;
    }
    block[remaining] ^= 0x06;
    block[rate - 1] ^= 0x80;
    for index in 0..rate {
        absorb_byte(&mut state, index, block[index]);
    }
    keccak_f(&mut state);

    let mut digest = [0u8; 64];
    for index in 0..digest_lengths[variant] {
        digest[index] = (state[index / 8] >> ((index % 8) * 8)) as u8;
    }
    digest
}

#[no_mangle]
pub unsafe extern "C" fn sha3(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if values[0] < 0 || values[0] > 3 || values[1] < 0 || values[1] > MAX_MESSAGE_BYTES as i64 { return -1; }
    let variant = values[0] as usize;
    let message_length = values[1] as usize;
    if input_length != 2 + message_length { return -1; }
    if values[2..].iter().any(|value| *value < 0 || *value > 255) { return -1; }

    let digest_lengths = [28usize, 32, 48, 64];
    let digest_length = digest_lengths[variant];
    if digest_length > MAX_OUTPUT_BYTES { return -1; }
    if output.is_null() || output_capacity < digest_length { return -2; }
    let digest = sha3_digest(variant, values);
    std::slice::from_raw_parts_mut(output, digest_length).copy_from_slice(&digest[..digest_length]);
    digest_length as i64
}

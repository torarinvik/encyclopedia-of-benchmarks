const CHACHA_WORDS: usize = 16;
const CHACHA_BYTES: usize = 64;
const WORD_MASK: u64 = 0xffff_ffff;

fn rotate_left(value: u64, count: u32) -> u64 {
    ((value << count) | (value >> (32 - count))) & WORD_MASK
}

fn quarter_round(state: &mut [u64; CHACHA_WORDS], a: usize, b: usize, c: usize, d: usize) {
    state[a] = (state[a] + state[b]) & WORD_MASK;
    state[d] = rotate_left(state[d] ^ state[a], 16);
    state[c] = (state[c] + state[d]) & WORD_MASK;
    state[b] = rotate_left(state[b] ^ state[c], 12);
    state[a] = (state[a] + state[b]) & WORD_MASK;
    state[d] = rotate_left(state[d] ^ state[a], 8);
    state[c] = (state[c] + state[d]) & WORD_MASK;
    state[b] = rotate_left(state[b] ^ state[c], 7);
}

#[no_mangle]
pub unsafe extern "C" fn chacha(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length != CHACHA_WORDS {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let mut initial = [0u64; CHACHA_WORDS];
    for index in 0..CHACHA_WORDS {
        if values[index] < 0 || values[index] as u64 > WORD_MASK {
            return -1;
        }
        initial[index] = values[index] as u64;
    }
    if output.is_null() || output_capacity < CHACHA_BYTES {
        return -2;
    }

    let mut state = initial;
    for _ in 0..10 {
        quarter_round(&mut state, 0, 4, 8, 12);
        quarter_round(&mut state, 1, 5, 9, 13);
        quarter_round(&mut state, 2, 6, 10, 14);
        quarter_round(&mut state, 3, 7, 11, 15);
        quarter_round(&mut state, 0, 5, 10, 15);
        quarter_round(&mut state, 1, 6, 11, 12);
        quarter_round(&mut state, 2, 7, 8, 13);
        quarter_round(&mut state, 3, 4, 9, 14);
    }
    let output = std::slice::from_raw_parts_mut(output, CHACHA_BYTES);
    for index in 0..CHACHA_WORDS {
        let word = ((state[index] + initial[index]) & WORD_MASK) as u32;
        output[4 * index..4 * index + 4].copy_from_slice(&word.to_le_bytes());
    }
    CHACHA_BYTES as i64
}

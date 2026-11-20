const STATE_SIZE: usize = 55;
const SHORT_LAG: usize = 24;
const WARMUP_VALUES: usize = 165;
const MODULUS: i32 = 1_000_000_000;

fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn subtractive_prng_bentley_seeded_sequence(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let seed = *input;
    let count = *input.add(1);
    if seed < 0 || seed >= i64::from(MODULUS) || count < 0 || count > 64 { return -1; }
    let n = count as usize;
    let required = n * 8;
    if capacity < required || (required != 0 && output.is_null()) { return -2; }
    if n == 0 { return 0; }

    let mut seed_state = [0i32; STATE_SIZE];
    let mut ring = [0i32; STATE_SIZE];
    seed_state[0] = seed as i32;
    seed_state[1] = 1;
    for i in 2..STATE_SIZE {
        let mut value = seed_state[i - 2] - seed_state[i - 1];
        if value < 0 { value += MODULUS; }
        seed_state[i] = value;
    }
    for i in 0..STATE_SIZE {
        ring[i] = seed_state[(34 * (i + 1)) % STATE_SIZE];
    }

    let mut write_index = 0;
    let mut lag_index = STATE_SIZE - SHORT_LAG;
    for step in 0..(WARMUP_VALUES + n) {
        let mut value = ring[write_index] - ring[lag_index];
        if value < 0 { value += MODULUS; }
        ring[write_index] = value;
        if step >= WARMUP_VALUES {
            put_i64_le(output, (step - WARMUP_VALUES) * 8, i64::from(value));
        }
        write_index = (write_index + 1) % STATE_SIZE;
        lag_index = (lag_index + 1) % STATE_SIZE;
    }
    required as i64
}

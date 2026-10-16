const MAX_LENGTH: usize = 1024;
const MODULUS: u64 = 2_147_483_647;

fn next_random(state: &mut u64) -> u64 {
    *state = (*state * 48_271) % MODULUS;
    *state
}

/// Fisher–Yates shuffle driven by a portable Park–Miller stream.
#[no_mangle]
pub unsafe extern "C" fn fisher_yates_shuffle(input: *const i64, length: usize, output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_LENGTH + 1 { return -1; }
    let seed = *input;
    if !(1..MODULUS as i64).contains(&seed) { return -1; }
    let count = length - 1;
    let byte_count = count * 4;
    let mut values = [0i32; MAX_LENGTH];
    for i in 0..count {
        let value = *input.add(i + 1);
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        values[i] = value as i32;
    }
    if output_capacity < byte_count || (byte_count != 0 && output.is_null()) { return -2; }
    let mut state = seed as u64;
    for remaining in (2..=count).rev() {
        let other = (next_random(&mut state) % remaining as u64) as usize;
        values.swap(remaining - 1, other);
    }
    for i in 0..count {
        let bits = values[i] as u32;
        for b in 0..4 { *output.add(i * 4 + b) = (bits >> (8 * b)) as u8; }
    }
    count as i64
}

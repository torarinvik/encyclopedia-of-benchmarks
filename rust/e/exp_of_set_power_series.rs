const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 5;
const MAX_SIZE: usize = 32;
const MAX_INPUT: usize = 33;

fn subset_size(mut mask: usize) -> usize {
    let mut count = 0;
    while mask != 0 {
        count += mask & 1;
        mask >>= 1;
    }
    count
}

unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn exp_of_set_power_series(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 0 || input[0] > MAX_N as i64 { return -1; }
    let n = input[0] as usize;
    let size = 1usize << n;
    if length != 1 + size || input[1] != 0 { return -1; }
    if input[1..].iter().any(|&value| value < 0 || value >= MODULUS) { return -1; }

    let bytes = 8 * size;
    if output.is_null() || capacity < bytes { return -2; }

    let mut inverse = [0_i64; MAX_N + 1];
    let mut values = [0_i64; MAX_SIZE];
    if n > 0 { inverse[1] = 1; }
    for k in 2..=n {
        inverse[k] = MODULUS - (MODULUS / k as i64) * inverse[(MODULUS % k as i64) as usize] % MODULUS;
    }
    values[0] = 1;
    for mask in 1..size {
        let mut total = 0_i64;
        let mut subset = mask;
        while subset != 0 {
            let mut term = (subset_size(subset) as i64 * input[1 + subset]) % MODULUS;
            term = term * values[mask ^ subset] % MODULUS;
            total = (total + term) % MODULUS;
            subset = (subset - 1) & mask;
        }
        values[mask] = total * inverse[subset_size(mask)] % MODULUS;
    }
    for mask in 0..size {
        unsafe { store_le(output, 8 * mask, values[mask]); }
    }
    bytes as i64
}

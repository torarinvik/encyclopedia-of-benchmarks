const MODULUS: i64 = 998_244_353;
const MAX_COEFFICIENTS: usize = 8;
const MAX_N: usize = 4;
const MAX_SIZE: usize = 16;
const MAX_INPUT: usize = 27;

fn store_le(output: &mut [u8], offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        output[offset + byte] = ((bits >> (8 * byte)) & 255) as u8;
    }
}

fn compose(input: &[i64], output: &mut [u8], count: usize, n: usize) -> i64 {
    let size = 1usize << n;
    let mut series = [0_i64; MAX_SIZE];
    let mut result = [0_i64; MAX_SIZE];
    let mut temporary = [0_i64; MAX_SIZE];
    for mask in 0..size {
        series[mask] = input[2 + count + mask];
    }

    for degree in (1..=count).rev() {
        for mask in 0..size {
            let mut total = 0_i64;
            let mut subset = mask;
            loop {
                total = (total + result[subset] * series[mask ^ subset]) % MODULUS;
                if subset == 0 { break; }
                subset = (subset - 1) & mask;
            }
            temporary[mask] = total;
        }
        temporary[0] = (temporary[0] + input[1 + degree]) % MODULUS;
        for mask in 0..size {
            result[mask] = temporary[mask];
        }
    }

    for mask in 0..size {
        store_le(output, 8 * mask, result[mask]);
    }
    (8 * size) as i64
}

#[no_mangle]
pub unsafe extern "C" fn polynomial_composite_set_power_series(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 0 || input[0] > MAX_COEFFICIENTS as i64 ||
        input[1] < 0 || input[1] > MAX_N as i64 { return -1; }
    let count = input[0] as usize;
    let n = input[1] as usize;
    let size = 1usize << n;
    if length != 2 + count + size { return -1; }
    if input[2..].iter().any(|&value| value < 0 || value >= MODULUS) { return -1; }

    let bytes = 8 * size;
    if output.is_null() || capacity < bytes { return -2; }
    let output = unsafe { std::slice::from_raw_parts_mut(output, bytes) };
    compose(input, output, count, n)
}

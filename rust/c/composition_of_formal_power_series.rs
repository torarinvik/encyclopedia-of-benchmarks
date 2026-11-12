const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 16;
const MAX_INPUT: usize = 34;

unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn composition_of_formal_power_series(input: *const i64, length: usize,
                                                              output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 1 || input[0] > MAX_N as i64 { return -1; }
    let n = input[0] as usize;
    if length != 1 + 2 * n { return -1; }
    if input[1..].iter().any(|&value| value < 0 || value >= MODULUS) || input[1 + n] != 0 { return -1; }
    let bytes = 8 * n;
    if output.is_null() || capacity < bytes { return -2; }

    let mut composed = [0_i64; MAX_N];
    for outer in (1..=n).rev() {
        for degree in (1..n).rev() {
            let mut sum = 0_i64;
            for inner_degree in 1..=degree {
                sum = (sum + composed[degree - inner_degree] * input[1 + n + inner_degree]) % MODULUS;
            }
            composed[degree] = sum;
        }
        composed[0] = input[outer];
    }
    for i in 0..n { unsafe { store_le(output, 8 * i, composed[i]); } }
    bytes as i64
}

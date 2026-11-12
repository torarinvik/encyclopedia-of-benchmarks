const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 64;
const MAX_INPUT: usize = 66;

unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn polynomial_taylor_shift(input: *const i64, length: usize,
                                                   output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 1 || input[0] > MAX_N as i64 { return -1; }
    let n = input[0] as usize;
    let shift = input[1];
    if length != n + 2 || shift < 0 || shift >= MODULUS { return -1; }
    for i in 0..n { if input[i + 2] < 0 || input[i + 2] >= MODULUS { return -1; } }

    let bytes = 8 * n;
    if output.is_null() || capacity < bytes { return -2; }
    let mut shifted = [0_i64; MAX_N];
    let mut processed = 0;
    for source in (0..n).rev() {
        let mut degree = processed;
        while degree > 0 {
            shifted[degree] = (shifted[degree] * shift + shifted[degree - 1]) % MODULUS;
            degree -= 1;
        }
        shifted[0] = (shifted[0] * shift + input[source + 2]) % MODULUS;
        processed += 1;
    }
    for i in 0..n { unsafe { store_le(output, 8 * i, shifted[i]); } }
    bytes as i64
}

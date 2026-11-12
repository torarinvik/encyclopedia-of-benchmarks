const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 4;
const MAX_M: usize = 8;
const MAX_SIZE: usize = 16;
const MAX_INPUT: usize = 35;

unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn power_projection_of_set_power_series(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 0 || input[0] > MAX_N as i64 || input[1] < 0 || input[1] > MAX_M as i64 { return -1; }
    let n = input[0] as usize;
    let powers = input[1] as usize;
    let size = 1usize << n;
    if length != 2 + 2 * size { return -1; }

    let mut series = [0_i64; MAX_SIZE];
    let mut weights = [0_i64; MAX_SIZE];
    for mask in 0..size {
        let a = input[2 + mask];
        let w = input[2 + size + mask];
        if a < 0 || a >= MODULUS || w < 0 || w >= MODULUS { return -1; }
        series[mask] = a;
        weights[mask] = w;
    }

    let bytes = 8 * powers;
    if output.is_null() || capacity < bytes { return -2; }

    let mut first = [0_i64; MAX_SIZE];
    let mut second = [0_i64; MAX_SIZE];
    let mut current = &mut first;
    let mut next = &mut second;
    current[0] = 1;
    for power in 0..powers {
        let mut projection = 0_i64;
        for mask in 0..size {
            projection = (projection + weights[mask] * current[mask]) % MODULUS;
        }
        unsafe { store_le(output, 8 * power, projection); }
        if power + 1 == powers { break; }
        for mask in 0..size {
            let mut total = 0_i64;
            let mut subset = mask;
            loop {
                total = (total + current[subset] * series[mask ^ subset]) % MODULUS;
                if subset == 0 { break; }
                subset = (subset - 1) & mask;
            }
            next[mask] = total;
        }
        std::mem::swap(&mut current, &mut next);
    }
    bytes as i64
}

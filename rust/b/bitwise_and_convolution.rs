const MAX_N: usize = 8;
const MAX_SIZE: usize = 1 << MAX_N;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_SIZE;
const MODULUS: i64 = 998_244_353;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn bitwise_and_convolution(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let n_value = *input;
    if !(0..=MAX_N as i64).contains(&n_value) {
        return -1;
    }
    let n = n_value as usize;
    let size = 1usize << n;
    if length != 1 + 2 * size {
        return -1;
    }
    for index in 0..2 * size {
        let value = *input.add(1 + index);
        if !(0..MODULUS).contains(&value) {
            return -1;
        }
    }
    let output_bytes = 8 * size;
    if output.is_null() || capacity < output_bytes {
        return -2;
    }

    let mut a = [0i64; MAX_SIZE];
    let mut b = [0i64; MAX_SIZE];
    for index in 0..size {
        a[index] = *input.add(1 + index);
        b[index] = *input.add(1 + size + index);
    }
    for bit in 0..n {
        let bit_mask = 1usize << bit;
        for mask in 0..size {
            if mask & bit_mask == 0 {
                a[mask] = (a[mask] + a[mask | bit_mask]) % MODULUS;
                b[mask] = (b[mask] + b[mask | bit_mask]) % MODULUS;
            }
        }
    }
    for mask in 0..size {
        a[mask] = (a[mask] * b[mask]) % MODULUS;
    }
    for bit in 0..n {
        let bit_mask = 1usize << bit;
        for mask in 0..size {
            if mask & bit_mask == 0 {
                a[mask] -= a[mask | bit_mask];
                if a[mask] < 0 {
                    a[mask] += MODULUS;
                }
            }
        }
    }
    for mask in 0..size {
        store_i64_le(output, 8 * mask, a[mask]);
    }
    output_bytes as i64
}

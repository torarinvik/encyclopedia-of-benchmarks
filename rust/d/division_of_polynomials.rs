const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 64;
const MAX_INPUT: usize = 131;
const MAX_OUTPUT_BYTES: usize = 536;

type Poly = [i64; MAX_N];

fn power_mod(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1_i64;
    while exponent > 0 {
        if (exponent & 1) != 0 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    result
}

fn trim(poly: &Poly, mut length: usize) -> usize {
    while length > 0 && poly[length - 1] == 0 { length -= 1; }
    length
}

unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn division_of_polynomials(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 1 || input[0] > MAX_N as i64 || input[1] < 1 || input[1] > MAX_N as i64 {
        return -1;
    }
    let n = input[0] as usize;
    let m = input[1] as usize;
    if length != 2 + n + m { return -1; }

    let mut work = [0_i64; MAX_N];
    let mut quotient = [0_i64; MAX_N];
    for i in 0..n {
        work[i] = input[2 + i];
        if work[i] < 0 || work[i] >= MODULUS { return -1; }
    }
    for i in 0..m {
        let coefficient = input[2 + n + i];
        if coefficient < 0 || coefficient >= MODULUS { return -1; }
    }
    if work[n - 1] == 0 || input[2 + n + m - 1] == 0 { return -1; }

    let mut quotient_bound = 0;
    if n >= m {
        quotient_bound = n - m + 1;
        let inverse_leading = power_mod(input[2 + n + m - 1], MODULUS - 2);
        let mut shift_plus_one = quotient_bound;
        while shift_plus_one > 0 {
            let shift = shift_plus_one - 1;
            let factor = work[shift + m - 1] * inverse_leading % MODULUS;
            quotient[shift] = factor;
            for j in 0..m {
                let mut value = (work[shift + j] - factor * input[2 + n + j]) % MODULUS;
                if value < 0 { value += MODULUS; }
                work[shift + j] = value;
            }
            shift_plus_one -= 1;
        }
    }

    let quotient_length = trim(&quotient, quotient_bound);
    let remainder_bound = n.min(m);
    let remainder_length = trim(&work, remainder_bound);
    let bytes = 8 * (2 + quotient_length + remainder_length);
    if bytes > MAX_OUTPUT_BYTES { return -1; }
    if output.is_null() || capacity < bytes { return -2; }

    unsafe {
        store_le(output, 0, quotient_length as i64);
        store_le(output, 8, remainder_length as i64);
        let mut offset = 16;
        for i in 0..quotient_length {
            store_le(output, offset, quotient[i]);
            offset += 8;
        }
        for i in 0..remainder_length {
            store_le(output, offset, work[i]);
            offset += 8;
        }
    }
    bytes as i64
}

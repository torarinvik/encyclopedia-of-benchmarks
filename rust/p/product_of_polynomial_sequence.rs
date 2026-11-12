const MODULUS: i64 = 998_244_353;
const MAX_FACTORS: usize = 6;
const MAX_COEFFICIENTS: usize = 25;
const MAX_INPUT: usize = 38;

unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn product_of_polynomial_sequence(input: *const i64,
        length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 0 || input[0] > MAX_FACTORS as i64 { return -1; }
    let count = input[0] as usize;
    let mut polynomials = [0_i64; MAX_FACTORS * MAX_COEFFICIENTS];
    let mut lengths = [0_usize; MAX_FACTORS];
    let mut cursor = 1;
    let mut degree_sum = 0;
    for p in 0..count {
        if cursor >= length || input[cursor] < 0 || input[cursor] > 4 { return -1; }
        let degree = input[cursor] as usize;
        cursor += 1;
        if cursor + degree + 1 > length { return -1; }
        for i in 0..=degree {
            let coefficient = input[cursor + i];
            if coefficient < 0 || coefficient >= MODULUS { return -1; }
            polynomials[p * MAX_COEFFICIENTS + i] = coefficient;
        }
        if polynomials[p * MAX_COEFFICIENTS + degree] == 0 { return -1; }
        lengths[p] = degree + 1;
        degree_sum += degree;
        cursor += degree + 1;
    }
    if cursor != length { return -1; }

    let result_length = degree_sum + 1;
    let bytes = 8 * result_length;
    if output.is_null() || capacity < bytes { return -2; }
    if count == 0 {
        unsafe { store_le(output, 0, 1); }
        return 8;
    }

    let mut scratch = [0_i64; MAX_COEFFICIENTS];
    let mut active = count;
    while active > 1 {
        let mut next_count = 0;
        let mut i = 0;
        while i < active {
            let destination = next_count * MAX_COEFFICIENTS;
            if i + 1 == active {
                let source = i * MAX_COEFFICIENTS;
                for j in 0..lengths[i] { polynomials[destination + j] = polynomials[source + j]; }
                lengths[next_count] = lengths[i];
            } else {
                let left_start = i * MAX_COEFFICIENTS;
                let right_start = (i + 1) * MAX_COEFFICIENTS;
                let product_length = lengths[i] + lengths[i + 1] - 1;
                for j in 0..product_length { scratch[j] = 0; }
                for a in 0..lengths[i] {
                    for b in 0..lengths[i + 1] {
                        let slot = a + b;
                        scratch[slot] = (scratch[slot] +
                            polynomials[left_start + a] * polynomials[right_start + b]) % MODULUS;
                    }
                }
                for j in 0..product_length { polynomials[destination + j] = scratch[j]; }
                lengths[next_count] = product_length;
            }
            next_count += 1;
            i += 2;
        }
        active = next_count;
    }
    for i in 0..result_length { unsafe { store_le(output, 8 * i, polynomials[i]); } }
    bytes as i64
}

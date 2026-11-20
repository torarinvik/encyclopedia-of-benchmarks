const MAX_N: usize = 32;
const MAX_INPUT_LENGTH: usize = 2;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), 8); }
}

#[no_mangle]
pub unsafe extern "C" fn cyclotomic_polynomial_coefficients(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length == 0 || length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    if !(1..=MAX_N as i64).contains(&n_value) || length != 1 { return -1; }
    let n = n_value as usize;

    let mut polynomials = [[0i64; MAX_N + 1]; MAX_N + 1];
    let mut degrees = [0usize; MAX_N + 1];
    polynomials[1][0] = -1;
    polynomials[1][1] = 1;
    degrees[1] = 1;
    for k in 2..=n {
        let mut divisor = [0i64; MAX_N + 1];
        divisor[0] = 1;
        let mut divisor_degree = 0usize;
        for d in 1..k {
            if k % d != 0 { continue; }
            let mut product = [0i64; MAX_N + 1];
            for i in 0..=divisor_degree {
                for j in 0..=degrees[d] {
                    product[i + j] += divisor[i] * polynomials[d][j];
                }
            }
            divisor_degree += degrees[d];
            divisor[..=divisor_degree].copy_from_slice(&product[..=divisor_degree]);
        }
        let mut remainder = [0i64; MAX_N + 1];
        remainder[0] = -1;
        remainder[k] = 1;
        let quotient_degree = k - divisor_degree;
        degrees[k] = quotient_degree;
        for q in (0..=quotient_degree).rev() {
            let leading = remainder[divisor_degree + q];
            polynomials[k][q] = leading;
            for j in 0..=divisor_degree {
                remainder[q + j] -= leading * divisor[j];
            }
        }
    }

    let coefficient_count = degrees[n] + 1;
    let required = coefficient_count * 8;
    if output.is_null() || capacity < required { return -2; }
    for index in 0..coefficient_count {
        store_i64_le(output, 8 * index, polynomials[n][index]);
    }
    required as i64
}

const MAX_DEGREE: usize = 8;
const MAX_ITERATIONS: usize = 4;
const MAX_INPUT_LENGTH: usize = 14;
const MODULUS: i64 = 998_244_353;

fn normalize(value: i64) -> i64 {
    let remainder = value % MODULUS;
    if remainder < 0 { remainder + MODULUS } else { remainder }
}

fn power(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1_i64;
    base = normalize(base);
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    result
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for (index, byte) in bytes.iter().enumerate() {
        unsafe { *output.add(offset + index) = *byte; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn bairstow_quadratic_factor_iteration(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let degree_value = values[0];
    if !(3..=MAX_DEGREE as i64).contains(&degree_value) { return -1; }
    let degree = degree_value as usize;
    if length != degree + 5 { return -1; }

    let mut coefficients = [0_i64; MAX_DEGREE + 1];
    for i in 0..=degree {
        coefficients[i] = values[1 + i];
        if coefficients[i] < 0 || coefficients[i] >= MODULUS { return -1; }
    }
    let mut s_value = values[degree + 2];
    let mut t_value = values[degree + 3];
    let iteration_value = values[degree + 4];
    if coefficients[degree] == 0 || s_value < 0 || s_value >= MODULUS
        || t_value < 0 || t_value >= MODULUS || !(1..=MAX_ITERATIONS as i64).contains(&iteration_value) {
        return -1;
    }
    let iterations = iteration_value as usize;
    let mut s_trace = [0_i64; MAX_ITERATIONS + 1];
    let mut t_trace = [0_i64; MAX_ITERATIONS + 1];
    s_trace[0] = s_value;
    t_trace[0] = t_value;
    for step in 0..iterations {
        let mut q = [0_i64; MAX_DEGREE + 2];
        let mut r = [0_i64; MAX_DEGREE + 2];
        q[degree] = coefficients[degree];
        r[degree] = coefficients[degree];
        for cursor in (0..degree).rev() {
            q[cursor] = normalize(coefficients[cursor] + s_value * q[cursor + 1]
                                  + t_value * q[cursor + 2]);
            r[cursor] = normalize(q[cursor] + s_value * r[cursor + 1]
                                  + t_value * r[cursor + 2]);
        }
        let (r2, r3, q0, q1) = (r[2], r[3], q[0], q[1]);
        let ell = normalize(s_value * r2 + t_value * r3);
        let denominator = normalize(r2 * r2 - ell * r3);
        if denominator == 0 { return -1; }
        let inverse = power(denominator, MODULUS - 2);
        let delta_s = normalize(r3 * q0 - r2 * q1) * inverse % MODULUS;
        let delta_t = normalize(ell * q1 - r2 * q0) * inverse % MODULUS;
        s_value = normalize(s_value + delta_s);
        t_value = normalize(t_value + delta_t);
        s_trace[step + 1] = s_value;
        t_trace[step + 1] = t_value;
    }

    let output_bytes = 8 * (2 * iterations + 3);
    if output.is_null() || capacity < output_bytes { return -2; }
    unsafe { store_i64_le(output, 0, (iterations + 1) as i64); }
    for i in 0..=iterations {
        unsafe { store_i64_le(output, 8 * (1 + 2 * i), s_trace[i]); }
        unsafe { store_i64_le(output, 8 * (2 + 2 * i), t_trace[i]); }
    }
    output_bytes as i64
}

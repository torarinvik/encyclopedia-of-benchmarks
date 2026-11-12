const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 8;
const MAX_INPUT: usize = 11;

fn normalize(value: i64) -> i64 {
    let reduced = value % MODULUS;
    if reduced < 0 { reduced + MODULUS } else { reduced }
}

fn power_mod(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1_i64;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    result
}

unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn polynomial_interpolation_on_geometric_sequence(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 0 || input[0] > MAX_N as i64 { return -1; }
    let n = input[0] as usize;
    let a = input[1];
    let r = input[2];
    if length != 3 + n || a < 0 || a >= MODULUS || r < 0 || r >= MODULUS { return -1; }

    let mut points = [0_i64; MAX_N];
    let mut differences = [0_i64; MAX_N];
    let mut newton = [0_i64; MAX_N];
    let mut point = a;
    for i in 0..n {
        points[i] = point;
        differences[i] = input[3 + i];
        if differences[i] < 0 || differences[i] >= MODULUS { return -1; }
        for j in 0..i { if points[i] == points[j] { return -1; } }
        point = point * r % MODULUS;
    }

    let bytes = 8 * n;
    if output.is_null() || capacity < bytes { return -2; }
    if n == 0 { return 0; }
    newton[0] = differences[0];
    for order in 1..n {
        let r_order = power_mod(r, order as i64);
        for end in (order + 1..=n).rev() {
            let i = end - 1;
            let r_factor = power_mod(r, (i - order) as i64);
            let mut denominator = a * r_factor % MODULUS;
            denominator = denominator * (r_order - 1) % MODULUS;
            let inverse = power_mod(normalize(denominator), MODULUS - 2);
            differences[i] = normalize((differences[i] - differences[i - 1]) * inverse);
        }
        newton[order] = differences[order];
    }

    let mut coefficients = [0_i64; MAX_N];
    let mut basis = [0_i64; MAX_N + 1];
    basis[0] = 1;
    let mut degree = 0;
    for order in 0..n {
        for k in 0..=degree {
            coefficients[k] = (coefficients[k] + newton[order] * basis[k]) % MODULUS;
        }
        if order + 1 == n { break; }
        let mut expanded = [0_i64; MAX_N + 1];
        for k in 0..=degree {
            expanded[k] = normalize(expanded[k] - basis[k] * points[order]);
            expanded[k + 1] = normalize(expanded[k + 1] + basis[k]);
        }
        for k in 0..=degree + 1 { basis[k] = expanded[k]; }
        degree += 1;
    }
    for i in 0..n { unsafe { store_le(output, 8 * i, coefficients[i]); } }
    bytes as i64
}

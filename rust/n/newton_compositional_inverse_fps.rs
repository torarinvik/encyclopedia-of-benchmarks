const MODULUS: i64 = 998_244_353;
type Series = [i64; 16];

fn power(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    result
}

fn multiply(left: &Series, right: &Series, width: usize) -> Series {
    let mut result = [0; 16];
    for i in 0..width {
        for j in 0..width - i {
            result[i + j] = (result[i + j] + left[i] * right[j]) % MODULUS;
        }
    }
    result
}

fn compose(outer: &Series, inner: &Series, width: usize) -> Series {
    let mut result = [0; 16];
    for &coefficient in outer[..width].iter().rev() {
        result = multiply(&result, inner, width);
        result[0] = (result[0] + coefficient) % MODULUS;
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn newton_compositional_inverse_fps(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(3..=18).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(2..=16).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    if length != n + 1 || values[1..].iter().any(|&x| !(0..MODULUS).contains(&x))
        || values[1] != 0 || values[2] == 0 { return -1; }
    let bytes = 8 * n;
    if output.is_null() || capacity < bytes { return -2; }
    let mut f = [0; 16];
    let mut derivative = [0; 16];
    let mut inverse = [0; 16];
    f[..n].copy_from_slice(&values[1..]);
    for i in 1..n { derivative[i - 1] = i as i64 * f[i] % MODULUS; }
    let inverse_linear = power(f[1], MODULUS - 2);
    inverse[1] = inverse_linear;
    let mut precision = 2;
    while precision < n {
        let width = (2 * precision).min(n);
        let mut residual = compose(&f, &inverse, width);
        residual[1] = (residual[1] + MODULUS - 1) % MODULUS;
        let slope = compose(&derivative, &inverse, width);
        let mut reciprocal = [0; 16];
        reciprocal[0] = inverse_linear;
        for i in 1..width {
            let mut sum = 0;
            for j in 1..=i { sum = (sum + slope[j] * reciprocal[i - j]) % MODULUS; }
            reciprocal[i] = (MODULUS - sum) * inverse_linear % MODULUS;
        }
        let correction = multiply(&residual, &reciprocal, width);
        for i in 0..width { inverse[i] = (inverse[i] + MODULUS - correction[i]) % MODULUS; }
        precision = width;
    }
    let destination = std::slice::from_raw_parts_mut(output, bytes);
    for (index, coefficient) in inverse[..n].iter().enumerate() {
        destination[index * 8..index * 8 + 8].copy_from_slice(&coefficient.to_le_bytes());
    }
    bytes as i64
}

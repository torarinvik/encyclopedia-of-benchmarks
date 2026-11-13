const MODULUS: i64 = 998_244_353;
const HALF: i64 = 499_122_177;
type Series = [i64; 64];

fn multiply(left: &Series, right: &Series, width: usize) -> Series {
    let mut result = [0; 64];
    for i in 0..width {
        for j in 0..width - i {
            result[i + j] = (result[i + j] + left[i] * right[j]) % MODULUS;
        }
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn newton_inverse_sqrt_fps(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=66).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=64).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    if length != n + 1 || values[1] != 1 || values[1..].iter().any(|&x| !(0..MODULUS).contains(&x)) {
        return -1;
    }
    let bytes = 8 * n;
    if output.is_null() || capacity < bytes { return -2; }
    let mut f = [0; 64];
    f[..n].copy_from_slice(&values[1..]);
    let mut inverse = [0; 64];
    inverse[0] = 1;
    let mut precision = 1;
    while precision < n {
        let width = (2 * precision).min(n);
        let square = multiply(&inverse, &inverse, width);
        let product = multiply(&f, &square, width);
        let mut correction = [0; 64];
        correction[0] = (3 + MODULUS - product[0]) * HALF % MODULUS;
        for i in 1..width { correction[i] = (MODULUS - product[i]) * HALF % MODULUS; }
        inverse = multiply(&inverse, &correction, width);
        precision = width;
    }
    let destination = std::slice::from_raw_parts_mut(output, bytes);
    for (i, value) in inverse[..n].iter().enumerate() {
        destination[8 * i..8 * i + 8].copy_from_slice(&value.to_le_bytes());
    }
    bytes as i64
}

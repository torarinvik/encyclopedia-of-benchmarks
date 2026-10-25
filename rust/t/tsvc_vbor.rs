const MAX_N: usize = 128;

/// Return the checksum produced by the bounded TSVC `vbor` polynomial kernel.
#[no_mangle]
pub unsafe extern "C" fn tsvc_vbor(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 7 || length > 1 + 6 * MAX_N { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let n_value = values[0];
    if !(1..=MAX_N as i64).contains(&n_value) { return -1; }
    let n = n_value as usize;
    if length != 1 + 6 * n || values[1..].iter().any(|&value| !(0..=2).contains(&value)) {
        return -1;
    }

    let mut checksum = 0i64;
    for i in 0..n {
        let a = values[1 + i];
        let b = values[1 + n + i];
        let c = values[1 + 2 * n + i];
        let d = values[1 + 3 * n + i];
        let e = values[1 + 4 * n + i];
        let f = values[1 + 5 * n + i];

        let a1 = a * b * c + a * b * d + a * b * e + a * b * f
            + a * c * d + a * c * e + a * c * f + a * d * e + a * d * f + a * e * f;
        let b1 = b * c * d + b * c * e + b * c * f + b * d * e + b * d * f + b * e * f;
        let c1 = c * d * e + c * d * f + c * e * f;
        let d1 = d * e * f;
        checksum += a1 * b1 * c1 * d1;
    }
    checksum
}

const MAX_N: usize = 64;
const MAX_PASSES: usize = 8;

/// Return the final checksum of the bounded TSVC s273 update sequence.
#[no_mangle]
pub unsafe extern "C" fn tsvc_s273_dependent_conditional_update(
    values: *const i64,
    length: usize,
) -> i64 {
    if values.is_null() || length < 7 || length > 2 + 5 * MAX_N { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let n_value = values[0];
    let passes_value = values[1];
    if !(1..=MAX_N as i64).contains(&n_value) || !(1..=MAX_PASSES as i64).contains(&passes_value) {
        return -1;
    }
    let n = n_value as usize;
    let passes = passes_value as usize;
    if length != 2 + 5 * n || values[2..].iter().any(|&x| !(-2..=2).contains(&x)) {
        return -1;
    }
    let mut a = values[2..2 + n].to_vec();
    let mut b = values[2 + n..2 + 2 * n].to_vec();
    let mut c = values[2 + 2 * n..2 + 3 * n].to_vec();
    let d = &values[2 + 3 * n..2 + 4 * n];
    let e = &values[2 + 4 * n..];

    for _ in 0..passes {
        for i in 0..n {
            a[i] += d[i] * e[i];
            if a[i] < 0 { b[i] += d[i] * e[i]; }
            c[i] += a[i] * d[i];
        }
    }
    a.iter().zip(&b).zip(&c).map(|((&x, &y), &z)| x + y + z).sum()
}

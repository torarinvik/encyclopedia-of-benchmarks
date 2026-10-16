const INVALID_RESULT: f64 = -1.0e300;
#[no_mangle]
pub unsafe extern "C" fn binary_cross_entropy(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 1 || length > 513 { return INVALID_RESULT; }
    let count_value = unsafe { *values };
    if count_value < 1 || count_value > 256 || length != (1 + 2 * count_value) as usize { return INVALID_RESULT; }
    let count = count_value as usize;
    for index in 0..count {
        let label = unsafe { *values.add(1 + index) };
        let probability = unsafe { *values.add(1 + count + index) };
        if (label != 0 && label != 1) || probability < 0 || probability > 1_000_000 { return INVALID_RESULT; }
    }
    let mut total = 0.0;
    for index in 0..count {
        let label = unsafe { *values.add(1 + index) } as f64;
        let mut probability = unsafe { *values.add(1 + count + index) } as f64 / 1_000_000.0;
        if probability < 1e-15 { probability = 1e-15; }
        if probability > 1.0 - 1e-15 { probability = 1.0 - 1e-15; }
        total -= label * probability.ln() + (1.0 - label) * (1.0 - probability).ln();
    }
    total / count as f64
}

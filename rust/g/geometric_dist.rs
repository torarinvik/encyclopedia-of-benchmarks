const INVALID_RESULT: f64 = -1.0e300;

fn geometric_cdf(p: f32, k: i64) -> f32 {
    1.0f32 - (1.0f32 - p).powf(k as f32)
}

/// Deterministic operations of the source's first-success geometric distribution.
#[no_mangle]
pub extern "C" fn geometric_dist(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 2 { return INVALID_RESULT; }
    let operation = unsafe { *values };
    let p_code = unsafe { *values.add(1) };
    if !(0..=2).contains(&p_code) { return INVALID_RESULT; }
    let probabilities = [0.25f32, 0.5f32, 0.75f32];
    let p = probabilities[p_code as usize];
    if (0..=2).contains(&operation) {
        if length != 2 { return INVALID_RESULT; }
        if operation == 0 { return (1.0f32 / p) as f64; }
        let variance = (1.0f32 - p) / (p * p);
        if operation == 1 { return variance as f64; }
        return variance.sqrt() as f64;
    }
    if operation == 3 || operation == 4 {
        if length != 3 { return INVALID_RESULT; }
        let k = unsafe { *values.add(2) };
        if operation == 3 && !(1..=16).contains(&k) { return INVALID_RESULT; }
        if operation == 4 && !(0..=16).contains(&k) { return INVALID_RESULT; }
        if operation == 3 { return ((1.0f32 - p).powf((k - 1) as f32) * p) as f64; }
        return geometric_cdf(p, k) as f64;
    }
    if operation == 5 {
        if length != 3 { return INVALID_RESULT; }
        let cdf_code = unsafe { *values.add(2) };
        if !(0..=2).contains(&cdf_code) { return INVALID_RESULT; }
        let cdf_values = [0.25f32, 0.5f32, 0.75f32];
        let cdf = cdf_values[cdf_code as usize];
        return ((1.0f32 - cdf).ln() / (1.0f32 - p).ln()) as f64;
    }
    if operation == 6 {
        if length != 4 { return INVALID_RESULT; }
        let minimum = unsafe { *values.add(2) };
        let maximum = unsafe { *values.add(3) };
        if minimum < 1 || maximum < minimum || maximum > 16 { return INVALID_RESULT; }
        return (geometric_cdf(p, maximum) - geometric_cdf(p, minimum - 1)) as f64;
    }
    INVALID_RESULT
}

/// Clean-room bounded GICOV recurrence; full applicable notice is in package LICENSE.txt.
#[no_mangle]
pub extern "C" fn rodinia_leukocyte_gicov(input: *const i64, length: usize) -> f64 {
    const BAD: f64 = -1.0e300;
    const ELLIPSES: usize = 7;
    const MAX_POINTS: usize = 16;
    if input.is_null() || length < 1 { return BAD; }
    let points_raw = unsafe { *input };
    if points_raw < 2 || points_raw > MAX_POINTS as i64 { return BAD; }
    let points = points_raw as usize;
    if length != 1 + ELLIPSES * points { return BAD; }
    let x = unsafe { std::slice::from_raw_parts(input, length) };
    if x[1..].iter().any(|&v| v < -1_000_000 || v > 1_000_000) { return BAD; }
    let decode = |raw: i64| -> f32 { raw as f32 / 1_000_000.0f32 };
    let mut maximum = 0.0f32;
    for ellipse in 0..ELLIPSES {
        let mut sum = 0.0f32;
        let mut mean = 0.0f32;
        let mut m2 = 0.0f32;
        let base = 1 + ellipse * points;
        for n in 0..points {
            let p = decode(x[base + n]);
            sum = sum + p;
            let delta = p - mean;
            mean = mean + delta / (n + 1) as f32;
            m2 = m2 + delta * (p - mean);
        }
        mean = sum / points as f32;
        let variance = m2 / (points - 1) as f32;
        if !(variance > 0.0) || !variance.is_finite() { return BAD; }
        let score = (mean * mean) / variance;
        if !score.is_finite() { return BAD; }
        if score > maximum { maximum = score; }
    }
    maximum as f64
}

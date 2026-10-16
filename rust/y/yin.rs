const INVALID_RESULT: f64 = -1.0e300;
const MAX_SAMPLES: usize = 256;
const MAX_LAG: usize = 64;

#[no_mangle]
pub extern "C" fn yin(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 7 || length > MAX_SAMPLES + 5 { return INVALID_RESULT; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (count_v, rate_v, min_hz_v, max_hz_v, threshold_v) = (values[0], values[1], values[2], values[3], values[4]);
    if count_v < 2 || count_v > MAX_SAMPLES as i64 || length != count_v as usize + 5 ||
        rate_v < 1 || rate_v > 192_000 || min_hz_v < 1 || max_hz_v <= min_hz_v ||
        max_hz_v > rate_v / 2 || threshold_v < 1 || threshold_v > 999_999 { return INVALID_RESULT; }
    let count = count_v as usize;
    let min_lag = (rate_v / max_hz_v) as usize;
    let max_lag = (rate_v / min_hz_v) as usize;
    if min_lag < 1 || min_lag > max_lag || max_lag > MAX_LAG || max_lag >= count { return INVALID_RESULT; }
    let samples = &values[5..];
    if samples.iter().any(|&sample| !(-32_768..=32_767).contains(&sample)) { return INVALID_RESULT; }
    let mut cmndf = vec![0.0; max_lag + 1];
    cmndf[0] = 1.0;
    let mut cumulative = 0.0;
    for lag in 1..=max_lag {
        let mut difference = 0.0;
        for i in 0..(count - lag) {
            let delta = samples[i] as f64 - samples[i + lag] as f64;
            difference += delta * delta;
        }
        cumulative += difference;
        cmndf[lag] = lag as f64 * difference / if cumulative == 0.0 { 1e-10 } else { cumulative };
    }
    let threshold = threshold_v as f64 / 1_000_000.0;
    let mut lag = min_lag;
    while lag <= max_lag {
        if cmndf[lag] < threshold {
            while lag < max_lag && cmndf[lag + 1] < cmndf[lag] { lag += 1; }
            let x0 = lag.saturating_sub(1);
            let x2 = usize::min(max_lag, lag + 1);
            let (s0, s1, s2) = (cmndf[x0], cmndf[lag], cmndf[x2]);
            let denominator = s0 - 2.0 * s1 + s2;
            let refined = if denominator == 0.0 { lag as f64 } else { lag as f64 + (s0 - s2) / (2.0 * denominator) };
            if !(refined > 0.0) { return INVALID_RESULT; }
            return rate_v as f64 / refined;
        }
        lag += 1;
    }
    INVALID_RESULT
}

const INVALID_RESULT: f64 = -1.0e300;

fn coefficients(kind: i64, frequency: f64, samplerate: f64,
               gain_db: f64, q_factor: f64) -> [f64; 6] {
    let w0 = 6.283185307179586476925286766559 * frequency / samplerate;
    let sine = w0.sin();
    let cosine = w0.cos();
    let alpha = sine / (2.0 * q_factor);
    let mut a0 = 1.0 + alpha;
    let mut a1 = -2.0 * cosine;
    let mut a2 = 1.0 - alpha;
    let (b0, b1, b2): (f64, f64, f64);
    if kind == 0 {
        b0 = (1.0 - cosine) / 2.0; b1 = 1.0 - cosine; b2 = b0;
    } else if kind == 1 {
        b0 = (1.0 + cosine) / 2.0; b1 = -1.0 - cosine; b2 = b0;
    } else if kind == 2 {
        b0 = sine / 2.0; b1 = 0.0; b2 = -b0;
    } else if kind == 3 {
        b0 = 1.0 - alpha; b1 = -2.0 * cosine; b2 = 1.0 + alpha;
        a0 = b2; a1 = b1; a2 = b0;
    } else if kind == 4 {
        let big_a = 10.0_f64.powf(gain_db / 40.0);
        b0 = 1.0 + alpha * big_a; b1 = -2.0 * cosine; b2 = 1.0 - alpha * big_a;
        a0 = 1.0 + alpha / big_a; a1 = -2.0 * cosine; a2 = 1.0 - alpha / big_a;
    } else if kind == 5 || kind == 6 {
        let big_a = 10.0_f64.powf(gain_db / 40.0);
        let pmc = (big_a + 1.0) - (big_a - 1.0) * cosine;
        let ppmc = (big_a + 1.0) + (big_a - 1.0) * cosine;
        let mpc = (big_a - 1.0) - (big_a + 1.0) * cosine;
        let pmpc = (big_a - 1.0) + (big_a + 1.0) * cosine;
        let aa2 = 2.0 * big_a.sqrt() * alpha;
        if kind == 5 {
            b0 = big_a * (pmc + aa2); b1 = 2.0 * big_a * mpc; b2 = big_a * (pmc - aa2);
            a0 = ppmc + aa2; a1 = -2.0 * pmpc; a2 = ppmc - aa2;
        } else {
            b0 = big_a * (ppmc + aa2); b1 = -2.0 * big_a * pmpc; b2 = big_a * (ppmc - aa2);
            a0 = pmc + aa2; a1 = 2.0 * mpc; a2 = pmc - aa2;
        }
    } else if kind == 7 {
        b0 = 1.0; b1 = -2.0 * cosine; b2 = 1.0;
    } else {
        b0 = alpha; b1 = 0.0; b2 = -alpha;
    }
    [a0, a1, a2, b0, b1, b2]
}

#[no_mangle]
pub unsafe extern "C" fn butterworth_filter(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 6 { return INVALID_RESULT; }
    let kind = *values;
    let coefficient_index = *values.add(1);
    let frequency = *values.add(2);
    let samplerate = *values.add(3);
    let gain_milli_db = *values.add(4);
    let q_micro = *values.add(5);
    if !(0..=8).contains(&kind) || !(0..=5).contains(&coefficient_index)
        || !(1..=95_999).contains(&frequency) || !(1..=192_000).contains(&samplerate)
        || 2 * frequency >= samplerate { return INVALID_RESULT; }
    if q_micro != -1 && !(1..=10_000_000).contains(&q_micro) { return INVALID_RESULT; }
    let needs_gain = (4..=6).contains(&kind);
    if needs_gain {
        if !(-60_000..=60_000).contains(&gain_milli_db) { return INVALID_RESULT; }
    } else if gain_milli_db != 0 { return INVALID_RESULT; }
    let gain_db = if needs_gain { gain_milli_db as f64 / 1000.0 } else { 0.0 };
    let q_factor = if q_micro == -1 { 1.0 / 2.0_f64.sqrt() } else { q_micro as f64 / 1_000_000.0 };
    coefficients(kind, frequency as f64, samplerate as f64, gain_db, q_factor)[coefficient_index as usize]
}

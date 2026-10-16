const MAX_INPUT_LENGTH: usize = 3 + 16 + 32 * 16;
const MAX_STATES: usize = 33;
const NEG_INF: f64 = -1.0e300;
const INVALID_RESULT: f64 = -1.0e300;

fn logaddexp_value(left: f64, right: f64) -> f64 {
    if left <= NEG_INF / 2.0 { return right; }
    if right <= NEG_INF / 2.0 { return left; }
    let larger = left.max(right);
    let smaller = left.min(right);
    larger + (1.0 + (smaller - larger).exp()).ln()
}

#[no_mangle]
pub unsafe extern "C" fn connectionist_temporal_classification_loss(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(values, length);
    let (time_value, classes_value, target_value) = (values[0], values[1], values[2]);
    if !(1..=32).contains(&time_value) || !(2..=16).contains(&classes_value) || !(1..=16).contains(&target_value) { return INVALID_RESULT; }
    let (time, classes, target_length) = (time_value as usize, classes_value as usize, target_value as usize);
    let probability_base = 3 + target_length;
    if length != probability_base + time * classes { return INVALID_RESULT; }
    let mut repeated = 0;
    for i in 0..target_length {
        let target = values[3 + i];
        if target < 1 || target as usize >= classes { return INVALID_RESULT; }
        if i > 0 && target == values[3 + i - 1] { repeated += 1; }
    }
    if time < target_length + repeated { return INVALID_RESULT; }
    for t in 0..time {
        let mut row_sum = 0i64;
        for c in 0..classes {
            let p = values[probability_base + t * classes + c];
            if !(1..=1_000_000).contains(&p) { return INVALID_RESULT; }
            row_sum += p;
        }
        if row_sum != 1_000_000 { return INVALID_RESULT; }
    }
    let states = 2 * target_length + 1;
    let mut extended = [0i64; MAX_STATES];
    let mut previous = [NEG_INF; MAX_STATES];
    let mut current = [NEG_INF; MAX_STATES];
    for s in 0..states { extended[s] = if s % 2 == 0 { 0 } else { values[3 + s / 2] }; }
    previous[0] = (values[probability_base] as f64 / 1_000_000.0).ln();
    previous[1] = (values[probability_base + extended[1] as usize] as f64 / 1_000_000.0).ln();
    for t in 1..time {
        for s in 0..states {
            let mut incoming = previous[s];
            if s > 0 { incoming = logaddexp_value(incoming, previous[s - 1]); }
            if s > 1 && extended[s] != extended[s - 2] { incoming = logaddexp_value(incoming, previous[s - 2]); }
            let p = values[probability_base + t * classes + extended[s] as usize] as f64 / 1_000_000.0;
            current[s] = incoming + p.ln();
        }
        previous[..states].copy_from_slice(&current[..states]);
    }
    -logaddexp_value(previous[states - 1], previous[states - 2])
}

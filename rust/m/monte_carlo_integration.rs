const MAX_N: i64 = 16;
const MIN_BOUND: i64 = -10_000_000;
const MAX_BOUND: i64 = 10_000_000;
const MAX_UNIFORM: i64 = 999_999;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn monte_carlo_integration(packed: *const i64, length: usize) -> f64 {
    if packed.is_null() || length < 3 || length > 12 {
        return INVALID_RESULT;
    }
    let packed = std::slice::from_raw_parts(packed, length);
    let n = packed[2];
    if !(1..=MAX_N).contains(&n) || length != (3 + (n + 1) / 2) as usize {
        return INVALID_RESULT;
    }
    let a_raw = packed[0];
    let b_raw = packed[1];
    if !(MIN_BOUND..=MAX_BOUND).contains(&a_raw)
        || !(MIN_BOUND..=MAX_BOUND).contains(&b_raw)
        || a_raw >= b_raw
        || packed[3..].iter().any(|&draw| !(0..=MAX_UNIFORM).contains(&draw))
    {
        return INVALID_RESULT;
    }

    let a = a_raw as f64 / 1_000_000.0;
    let b = b_raw as f64 / 1_000_000.0;
    let interval = b - a;
    let mut total = 0.0;
    for index in 0..(n / 2) as usize {
        let u = packed[3 + index] as f64 / 1_000_000.0;
        let x1 = a + u * interval;
        let x2 = a + (1.0 - u) * interval;
        total += x1 * x1;
        total += x2 * x2;
    }
    if n % 2 == 1 {
        let u = packed[3 + (n / 2) as usize] as f64 / 1_000_000.0;
        let x = a + u * interval;
        total += x * x;
    }
    interval * total / n as f64
}

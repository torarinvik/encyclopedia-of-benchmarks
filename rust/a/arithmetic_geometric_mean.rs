const MAX_VALUE: f64 = 1_000_000.0;
const INVALID_RESULT: f64 = -1.0;

#[no_mangle]
pub extern "C" fn arithmetic_geometric_mean(first: f64, second: f64) -> f64 {
    if first.is_nan() || second.is_nan() || first < 0.0 || second < 0.0 ||
        first > MAX_VALUE || second > MAX_VALUE {
        return INVALID_RESULT;
    }
    if first == second {
        return first;
    }

    let mut arithmetic = first;
    let mut geometric = second;
    loop {
        let previous = arithmetic;
        let next_arithmetic = (arithmetic + geometric) / 2.0;
        let next_geometric = (arithmetic * geometric).sqrt();
        arithmetic = next_arithmetic;
        geometric = next_geometric;
        if arithmetic == previous {
            break;
        }
    }
    arithmetic
}

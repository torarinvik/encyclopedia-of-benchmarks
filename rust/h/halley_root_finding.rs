#[no_mangle]
pub extern "C" fn halley_root_finding(initial_x: f64, iteration_count: f64) -> f64 {
    if !initial_x.is_finite()
        || !iteration_count.is_finite()
        || !(0.5..=2.0).contains(&initial_x)
        || !(0.0..=8.0).contains(&iteration_count)
        || iteration_count.fract() != 0.0
    {
        return -1.0;
    }

    let mut x = initial_x;
    for _ in 0..iteration_count as usize {
        let value = x * x * x - 2.0;
        let first = 3.0 * x * x;
        let second = 6.0 * x;
        let denominator = 2.0 * first * first - value * second;
        if denominator == 0.0 || !denominator.is_finite() {
            return -1.0;
        }
        x -= (2.0 * value * first) / denominator;
        if !x.is_finite() {
            return -1.0;
        }
    }
    x
}

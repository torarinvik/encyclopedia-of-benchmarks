#[no_mangle]
pub extern "C" fn modified_newton_multiple_root(initial_x: f64, iteration_count: f64) -> f64 {
    if !initial_x.is_finite()
        || !iteration_count.is_finite()
        || !(1.0..=2.0).contains(&initial_x)
        || !(0.0..=8.0).contains(&iteration_count)
        || iteration_count.fract() != 0.0
    {
        return -1.0;
    }

    let mut x = initial_x;
    for _ in 0..iteration_count as usize {
        if x == 1.0 {
            break;
        }
        let offset = x - 1.0;
        let value = offset * offset * (x + 2.0);
        let derivative = 3.0 * offset * (x + 1.0);
        if derivative == 0.0 || !derivative.is_finite() {
            return -1.0;
        }
        x -= 2.0 * (value / derivative);
        if !x.is_finite() || !(1.0..=2.0).contains(&x) {
            return -1.0;
        }
    }
    x
}

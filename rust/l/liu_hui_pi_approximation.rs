#[no_mangle]
pub unsafe extern "C" fn liu_hui_pi_approximation(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 1 {
        return -1;
    }
    let doublings = *values;
    if !(0..=16).contains(&doublings) {
        return -1;
    }

    let mut sides = 6i64;
    let mut side = 1.0f64;
    let mut apothem = 0.75f64.sqrt();
    for _ in 0..doublings {
        let half_side = side / 2.0;
        let height = 1.0 - apothem;
        side = (half_side * half_side + height * height).sqrt();
        sides *= 2;
        let next_half_side = side / 2.0;
        apothem = (1.0 - next_half_side * next_half_side).sqrt();
    }

    let area = sides as f64 * side * apothem / 2.0;
    (area * 1_000_000.0 + 0.5) as i64
}

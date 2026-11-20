#[no_mangle]
pub extern "C" fn cosine_fixed_point_iteration(initial_input: f64, source_n: f64) -> f64 {
    if !initial_input.is_finite()
        || !source_n.is_finite()
        || !(0.0..=2.0).contains(&initial_input)
        || !(0.0..=64.0).contains(&source_n)
        || source_n.fract() != 0.0
    {
        return -1.0;
    }

    let mut value = initial_input;
    let updates = source_n as usize + 1;
    for _ in 0..updates {
        value = 0.5 * (value.cos() + 2.0);
    }
    value
}

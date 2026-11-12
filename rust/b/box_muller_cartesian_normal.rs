const MAX_PAIRS: usize = 64;
const DRAW_SCALE: f64 = 4_294_967_296.0;
const TAU: f64 = 6.283185307179586476925286766559;

fn is_bounded_integer(value: f64, minimum: f64, maximum: f64) -> bool {
    value.is_finite() && value.fract() == 0.0 && value >= minimum && value <= maximum
}

#[no_mangle]
pub unsafe extern "C" fn box_muller_cartesian_normal(
    input: *const f64,
    length: usize,
    output: *mut f64,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 1 + 2 * MAX_PAIRS { return -1; }
    let pair_count_value = *input;
    if !is_bounded_integer(pair_count_value, 1.0, MAX_PAIRS as f64) { return -1; }
    let pair_count = pair_count_value as usize;
    if length != 1 + 2 * pair_count { return -1; }
    for index in 0..2 * pair_count {
        let draw = *input.add(1 + index);
        if !is_bounded_integer(draw, 0.0, 4_294_967_295.0) { return -1; }
    }

    let result_count = 2 * pair_count;
    if output.is_null() || capacity < result_count { return -2; }
    for pair in 0..pair_count {
        let radial = (*input.add(1 + 2 * pair) + 1.0) / DRAW_SCALE;
        let angular = *input.add(2 + 2 * pair) / DRAW_SCALE;
        let radius = (-2.0 * radial.ln()).sqrt();
        let angle = TAU * angular;
        *output.add(2 * pair) = radius * angle.cos();
        *output.add(2 * pair + 1) = radius * angle.sin();
    }
    result_count as i64
}

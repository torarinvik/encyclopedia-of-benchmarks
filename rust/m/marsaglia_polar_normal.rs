const MAX_DRAWS: usize = 128;
const MAX_ATTEMPTS: usize = 64;
const DRAW_SCALE: f64 = 2_147_483_648.0;

fn is_bounded_integer(value: f64, minimum: f64, maximum: f64) -> bool {
    value.is_finite() && value.fract() == 0.0 && value >= minimum && value <= maximum
}

#[no_mangle]
pub unsafe extern "C" fn marsaglia_polar_normal(
    input: *const f64,
    length: usize,
    output: *mut f64,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > 2 + MAX_DRAWS { return -1; }
    let draw_count_value = *input;
    let attempt_cap_value = *input.add(1);
    if !is_bounded_integer(draw_count_value, 2.0, MAX_DRAWS as f64)
        || !is_bounded_integer(attempt_cap_value, 1.0, MAX_ATTEMPTS as f64)
    { return -1; }
    let draw_count = draw_count_value as usize;
    let attempt_cap = attempt_cap_value as usize;
    if draw_count % 2 != 0 || length != 2 + draw_count || draw_count < 2 * attempt_cap { return -1; }
    for index in 0..draw_count {
        let value = *input.add(2 + index);
        if !is_bounded_integer(value, 0.0, 4_294_967_295.0) { return -1; }
    }

    let mut first = 0.0;
    let mut second = 0.0;
    let mut accepted = false;
    for attempt in 0..attempt_cap {
        let u1 = *input.add(2 + 2 * attempt) / DRAW_SCALE - 1.0;
        let u2 = *input.add(3 + 2 * attempt) / DRAW_SCALE - 1.0;
        let radius_squared = u1 * u1 + u2 * u2;
        if radius_squared <= 0.0 || radius_squared >= 1.0 { continue; }
        let scale = (-2.0 * radius_squared.ln() / radius_squared).sqrt();
        first = u1 * scale;
        second = u2 * scale;
        accepted = true;
        break;
    }
    if !accepted { return -1; }
    if output.is_null() || capacity < 2 { return -2; }
    *output = first;
    *output.add(1) = second;
    2
}

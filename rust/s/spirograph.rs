use std::f64::consts::PI;

const MAX_INPUT_LENGTH: usize = 5;
const MAX_POINTS: usize = 32;

fn exact_integer(value: f64, minimum: i64, maximum: i64) -> Option<i64> {
    if !value.is_finite() || value.trunc() != value || value < minimum as f64 || value > maximum as f64 {
        return None;
    }
    Some(value as i64)
}

#[no_mangle]
pub unsafe extern "C" fn spirograph(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if input_length != 4 { return -1; }
    let points = match exact_integer(values[0], 1, MAX_POINTS as i64) { Some(value) => value as usize, None => return -1 };
    let marker_ratio = values[1];
    let inner_ratio = values[2];
    let rotations = values[3];
    if !marker_ratio.is_finite() || !(0.0..=1.0).contains(&marker_ratio)
        || !inner_ratio.is_finite() || !(0.25..=0.75).contains(&inner_ratio)
        || !rotations.is_finite() || !(0.0..=10.0).contains(&rotations) { return -1; }

    let delta = rotations * 2.0 * PI / points as f64;
    let k1 = 1.0 - inner_ratio;
    let mut staged = [0.0_f64; 64];
    for index in 0..points {
        let t = index as f64 * delta;
        let inner_angle = k1 * t / inner_ratio;
        let x = k1 * t.cos() + marker_ratio * inner_ratio * inner_angle.cos();
        let y = k1 * t.sin() - marker_ratio * inner_ratio * inner_angle.sin();
        if !x.is_finite() || !y.is_finite() { return -1; }
        staged[2 * index] = x;
        staged[2 * index + 1] = y;
    }

    let output_length = 2 * points;
    if output.is_null() || output_capacity < output_length { return -2; }
    for index in 0..output_length { *output.add(index) = staged[index]; }
    output_length as i64
}

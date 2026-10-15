/// Composite trapezoidal integration for constant, linear, and quadratic samples.
const MAX_STEPS: i64 = 10_000;
const MAX_COORD_MILLI: i64 = 100_000;
const OUTPUT_SCALE: f64 = 1_000_000.0;

fn sample_value(function_id: i64, x: f64) -> f64 {
    match function_id {
        0 => 5.0,
        1 => x,
        _ => x * x,
    }
}

#[no_mangle]
pub unsafe extern "C" fn area_under_curve(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 4 { return -1; }
    let function_id = *input;
    let start_milli = *input.add(1);
    let end_milli = *input.add(2);
    let steps = *input.add(3);
    if !(0..=2).contains(&function_id) || !(0..=MAX_COORD_MILLI).contains(&start_milli) ||
        !(0..=MAX_COORD_MILLI).contains(&end_milli) || !(1..=MAX_STEPS).contains(&steps) { return -1; }
    let low_milli = start_milli.min(end_milli);
    let high_milli = start_milli.max(end_milli);
    let start = low_milli as f64 / 1000.0;
    let end = high_milli as f64 / 1000.0;
    let width = (end - start) / steps as f64;
    let mut x1 = start;
    let mut y1 = sample_value(function_id, x1);
    let mut area = 0.0;
    for _ in 0..steps {
        let x2 = x1 + width;
        let y2 = sample_value(function_id, x2);
        area += (y1 + y2) * width * 0.5;
        x1 = x2;
        y1 = y2;
    }
    (area * OUTPUT_SCALE + 0.5) as i64
}

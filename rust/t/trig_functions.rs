const PI: f64 = 3.14159265358979323846;

fn rounded_six(value: f64) -> f64 { (value * 1_000_000.0).round() / 1_000_000.0 }

fn trig_series(mut value: f64, tolerance: f64, kind: i32) -> f64 {
    let period = 2.0 * PI;
    while value >= period { value -= period; }
    while value <= -period { value += period; }
    let mut result = 0.0_f64;
    let mut previous = 1.0_f64;
    let mut step = 0_i32;
    while (previous - result).abs() > tolerance {
        previous = result;
        let power = 2 * step + kind;
        let mut factorial = 1.0_f64;
        for factor in 2..=power { factorial *= factor as f64; }
        result += (-1.0_f64).powi(step) * value.powi(power) / factorial;
        step += 1;
    }
    rounded_six(result)
}

#[no_mangle]
pub unsafe extern "C" fn trig_functions(input: *const f64, length: usize,
                                          output: *mut f64, capacity: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let selector_value = unsafe { *input };
    let mut x = unsafe { *input.add(1) };
    let tolerance = unsafe { *input.add(2) };
    if !selector_value.is_finite() || selector_value < 0.0 || selector_value > 7.0 || selector_value.fract() != 0.0 { return -1; }
    if !tolerance.is_finite() || !(1e-9..=1e-2).contains(&tolerance) { return -1; }
    if x.is_finite() && !(-10_000.0..=10_000.0).contains(&x) { return -1; }
    if output.is_null() || capacity < 1 { return -2; }
    if !x.is_finite() { unsafe { *output = f64::NAN; } return 1; }

    let selector = selector_value as i32;
    if matches!(selector, 2 | 3 | 6 | 7) { x = x * PI / 180.0; }
    let result = match selector {
        0 | 2 => trig_series(x, tolerance, 1),
        1 | 3 => trig_series(x, tolerance, 0),
        4 | 6 => {
            let denominator = trig_series(x, tolerance, 0);
            if denominator == 0.0 { f64::NAN } else { trig_series(x, tolerance, 1) / denominator }
        }
        _ => {
            let denominator = trig_series(x, tolerance, 1);
            if denominator == 0.0 { f64::NAN } else { trig_series(x, tolerance, 0) / denominator }
        }
    };
    unsafe { *output = result; }
    1
}

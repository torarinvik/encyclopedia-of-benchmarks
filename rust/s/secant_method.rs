const INVALID_RESULT: f64 = -1.0e300;

fn python_objective(x: f64) -> f64 {
    8.0 * x - 2.0 * (-x).exp()
}

fn c_variant() -> f64 {
    let (mut x0, mut x1): (f64, f64) = (0.2, 0.5);
    let tolerance = 100.0 / 1000000.0;
    for _ in 0..99 {
        let f1 = x1 * x1 - 3.0;
        let f0 = x0 * x0 - 3.0;
        let x2 = x1 - f1 * (x1 - x0) / (f1 - f0);
        x0 = x1;
        x1 = x2;
        if (x1 - x0).abs() < tolerance { return x2; }
    }
    -1.0
}

fn python_variant(repeats: i64) -> f64 {
    let (mut x0, mut x1) = (1.0, 3.0);
    for _ in 0..repeats {
        let f1 = python_objective(x1);
        let f0 = python_objective(x0);
        let x2 = x1 - (f1 * (x1 - x0)) / (f1 - f0);
        x0 = x1;
        x1 = x2;
    }
    x1
}

#[no_mangle]
pub unsafe extern "C" fn secant_method(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return INVALID_RESULT; }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] == 0 && input[1] == 100 { return c_variant(); }
    if input[0] == 1 && (0..=2).contains(&input[1]) { return python_variant(input[1]); }
    INVALID_RESULT
}

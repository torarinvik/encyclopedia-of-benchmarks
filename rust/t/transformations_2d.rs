const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn transformations_2d(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return INVALID_RESULT; }
    let input = std::slice::from_raw_parts(values, length);
    let operation = input[0];
    let parameter_micro = input[1];
    let component = input[2];
    if !(0..=3).contains(&operation) || !(0..=3).contains(&component) { return INVALID_RESULT; }

    let matrix = if operation == 0 {
        if !(-1_000_000..=1_000_000).contains(&parameter_micro) { return INVALID_RESULT; }
        let factor = parameter_micro as f64 / 1_000_000.0;
        [factor * 1.0, factor * 0.0, factor * 0.0, factor * 1.0]
    } else {
        if !(-6_283_185..=6_283_185).contains(&parameter_micro) { return INVALID_RESULT; }
        let angle = parameter_micro as f64 / 1_000_000.0;
        let c = angle.cos();
        let s = angle.sin();
        match operation {
            1 => [c, -s, s, c],
            2 => {
                let cs = c * s;
                [c * c, cs, cs, s * s]
            }
            _ => {
                let cs = c * s;
                [2.0 * c - 1.0, 2.0 * cs, 2.0 * cs, 2.0 * s - 1.0]
            }
        }
    };
    matrix[component as usize]
}

const INVALID_RESULT: f64 = -1.0e300;
type Objective = fn(f32) -> f32;

fn minimum_function(x: f32) -> f32 { x * x - 2.0 * x + 3.0 }
fn maximum_function(x: f32) -> f32 { -x * x - 2.0 * x + 3.0 }

fn ternary_min(f: Objective, start: f32, end: f32, precision: f32) -> f32 {
    if (end - start).abs() >= precision {
        let mid1 = start + (end - start) / 3.0;
        let mid2 = end - (end - start) / 3.0;
        let r1 = f(mid1);
        let r2 = f(mid2);
        if r1 < r2 { return ternary_min(f, start, mid2, precision); }
        if r1 > r2 { return ternary_min(f, mid1, end, precision); }
        return ternary_min(f, mid1, mid2, precision);
    }
    f(start)
}

fn ternary_max(f: Objective, start: f32, end: f32, precision: f32) -> f32 {
    if (end - start).abs() >= precision {
        let mid1 = start + (end - start) / 3.0;
        let mid2 = end - (end - start) / 3.0;
        let r1 = f(mid1);
        let r2 = f(mid2);
        if r1 < r2 { return ternary_max(f, mid1, end, precision); }
        if r1 > r2 { return ternary_max(f, start, mid2, precision); }
        return ternary_max(f, mid1, mid2, precision);
    }
    f(start)
}

#[no_mangle]
pub unsafe extern "C" fn ternary_search_min_max_recursive(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 4 { return INVALID_RESULT; }
    let input = std::slice::from_raw_parts(values, length);
    let mode = input[0];
    let start_milli = input[1];
    let end_milli = input[2];
    let precision_milli = input[3];
    let center_milli = if mode == 0 { 1000 } else if mode == 1 { -1000 } else { 0 };
    if !(0..=1).contains(&mode) || start_milli < -100000 || end_milli > 100000 ||
        start_milli >= center_milli || end_milli <= center_milli || !(1..=8).contains(&precision_milli) {
        return INVALID_RESULT;
    }
    let start = start_milli as f32 / 1000.0;
    let end = end_milli as f32 / 1000.0;
    let precision = precision_milli as f32 / 1000.0;
    f64::from(if mode == 0 {
        ternary_min(minimum_function, start, end, precision)
    } else {
        ternary_max(maximum_function, start, end, precision)
    })
}

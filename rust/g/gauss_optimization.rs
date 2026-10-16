fn objective(x1: f64, x2: f64, target1: f64, target2: f64) -> f64 {
    let dx = x1 - target1;
    let dy = x2 - target2;
    -(dx * dx + dy * dy)
}

#[no_mangle]
pub unsafe extern "C" fn gauss_optimization(
    values: *const f64, length: usize, output: *mut f64, capacity: usize,
) -> i64 {
    if values.is_null() || length != 7 { return -1; }
    let v = std::slice::from_raw_parts(values, length);
    if v.iter().any(|value| !value.is_finite()) ||
        !(v[0] == 2.0 || v[0] == 3.0 || v[0] == 4.0) ||
        !(0.25..=4.0).contains(&v[1]) || !(1e-6..=2.0).contains(&v[2]) ||
        v[3..7].iter().any(|coordinate| !(-8.0..=8.0).contains(coordinate)) {
        return -1;
    }
    if output.is_null() || capacity < 2 { return -2; }

    let factor = v[0];
    let mut step = v[1];
    let epsilon = v[2];
    let (mut x1, mut x2, target1, target2) = (v[3], v[4], v[5], v[6]);
    let mut error: f64 = 1.0;
    let mut iteration = 0;
    while error.abs() > epsilon && iteration < 256 {
        let current = objective(x1, x2, target1, target2);
        let mut best = objective(x1, x2 - step, target1, target2);
        let mut choice = 0;
        let mut candidate = objective(x1, x2 + step, target1, target2);
        if candidate > best { best = candidate; choice = 1; }
        candidate = objective(x1 - step, x2, target1, target2);
        if candidate > best { best = candidate; choice = 2; }
        candidate = objective(x1 + step, x2, target1, target2);
        if candidate > best { best = candidate; choice = 3; }
        error = best - current;
        if choice == 0 { x2 -= step; }
        else if choice == 1 { x2 += step; }
        else if choice == 2 { x1 -= step; }
        else { x1 += step; }
        step /= factor;
        iteration += 1;
    }
    if error.abs() > epsilon { return -1; }
    let result = std::slice::from_raw_parts_mut(output, 2);
    result[0] = x1;
    result[1] = x2;
    2
}

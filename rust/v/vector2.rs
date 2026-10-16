#[no_mangle]
pub unsafe extern "C" fn vector2(
    values: *const f64,
    length: usize,
    output: *mut f64,
    capacity: usize,
) -> i64 {
    if values.is_null() || length != 6 { return -1; }
    let v = std::slice::from_raw_parts(values, length);
    if v.iter().any(|value| !value.is_finite()) ||
        !(0.0..=10.0).contains(&v[0]) || v[0].fract() != 0.0 ||
        v[1..5].iter().any(|coordinate| !(-1000.0..=1000.0).contains(coordinate)) {
        return -1;
    }

    let op = v[0] as i32;
    let (ax, ay, bx, by, scalar) = (v[1], v[2], v[3], v[4], v[5]);
    if op == 1 {
        if !(0.0..=2000.0).contains(&scalar) { return -1; }
    } else if op == 6 {
        if bx != 0.0 || by != 0.0 || !(-1000.0..=1000.0).contains(&scalar) { return -1; }
    } else if op == 9 {
        if bx != 0.0 || by != 0.0 || !(-6.283185307179586..=6.283185307179586).contains(&scalar) { return -1; }
    } else if scalar != 0.0 { return -1; }
    if (op == 2 || op == 3) && (bx != 0.0 || by != 0.0) { return -1; }

    let mut result = [0.0, 0.0];
    let mut result_length = 1usize;
    match op {
        0 => result[0] = if ax == bx && ay == by { 1.0 } else { 0.0 },
        1 => result[0] = if (ax - bx).abs() < scalar && (ay - by).abs() < scalar { 1.0 } else { 0.0 },
        2 => result[0] = (ax * ax + ay * ay).sqrt(),
        3 => {
            let magnitude = (ax * ax + ay * ay).sqrt();
            if magnitude == 0.0 { return -1; }
            result_length = 2;
            result[0] = ax / magnitude;
            result[1] = ay / magnitude;
        }
        4 => { result_length = 2; result[0] = ax + bx; result[1] = ay + by; }
        5 => { result_length = 2; result[0] = ax - bx; result[1] = ay - by; }
        6 => { result_length = 2; result[0] = ax * scalar; result[1] = ay * scalar; }
        7 => {
            let dx = bx - ax;
            let dy = by - ay;
            result[0] = (dx * dx + dy * dy).sqrt();
        }
        8 => result[0] = ax * bx + ay * by,
        9 => {
            let cosine = scalar.cos();
            let sine = scalar.sin();
            result_length = 2;
            result[0] = cosine * ax - sine * ay;
            result[1] = sine * ax + cosine * ay;
        }
        _ => result[0] = by.atan2(bx) - ay.atan2(ax),
    }

    if output.is_null() || capacity < result_length { return -2; }
    for i in 0..result_length { *output.add(i) = result[i]; }
    result_length as i64
}

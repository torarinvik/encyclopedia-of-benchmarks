const MIN_COORDINATE: i64 = 900;
const MAX_COORDINATE: i64 = 1500;
const MAX_UPDATES: i64 = 8;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), 8); }
}

fn round_nano(value: f64) -> i64 {
    let magnitude = if value < 0.0 { -value } else { value };
    let rounded = (magnitude * 1_000_000_000.0 + 0.5).floor() as i64;
    if value < 0.0 { -rounded } else { rounded }
}

#[no_mangle]
pub unsafe extern "C" fn multidimensional_newton_raphson(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=4).contains(&length) { return -1; }
    if length != 3 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (x_milli, y_milli, updates) = (values[0], values[1], values[2]);
    if x_milli < MIN_COORDINATE || x_milli > MAX_COORDINATE
            || y_milli < MIN_COORDINATE || y_milli > MAX_COORDINATE
            || updates < 1 || updates > MAX_UPDATES { return -1; }
    if output.is_null() || capacity < 16 { return -2; }

    let mut x = x_milli as f64 / 1000.0;
    let mut y = y_milli as f64 / 1000.0;
    for _ in 0..updates {
        let f1 = x * x + y - 3.0;
        let f2 = x + y * y - 3.0;
        let determinant = 4.0 * x * y - 1.0;
        let dx = (2.0 * y * f1 - f2) / determinant;
        let dy = (2.0 * x * f2 - f1) / determinant;
        x -= dx;
        y -= dy;
    }
    store_i64_le(output, 0, round_nano(x));
    store_i64_le(output, 8, round_nano(y));
    16
}

/// Bounded Adams-Bashforth methods for y' = x + y on a quarter-step grid.
fn append_integer(mut value: i64, out: &mut [u8], mut position: usize) -> usize {
    let mut digits = [0u8; 24];
    let mut count = 0usize;
    if value < 0 { out[position] = b'-'; position += 1; value = -value; }
    loop {
        digits[count] = (value % 10) as u8;
        count += 1;
        value /= 10;
        if value == 0 { break; }
    }
    while count > 0 {
        count -= 1;
        out[position] = b'0' + digits[count];
        position += 1;
    }
    position
}

#[no_mangle]
pub unsafe extern "C" fn adams_bashforth(values: *const i64, length: usize,
                                            output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length < 4 { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let order_arg = values[0];
    let steps_arg = values[1];
    if !(2..=5).contains(&order_arg) || !(1..=4).contains(&steps_arg) || length != order_arg as usize + 2 {
        return -1;
    }
    let order = order_arg as usize;
    let steps = steps_arg as usize;
    if values[2..].iter().any(|&v| !(-100000..=100000).contains(&v)) { return -1; }
    let mut x = [0.0f64; 14];
    let mut y = [0.0f64; 14];
    for i in 0..order {
        x[i] = i as f64 * 0.25;
        y[i] = values[i + 2] as f64 / 100000.0;
    }
    let coefficients: &[i64] = match order {
        2 => &[3, -1],
        3 => &[23, -16, 5],
        4 => &[55, -59, 37, -9],
        _ => &[1901, -2774, -2616, -1274, 251],
    };
    let denominator = match order { 2 => 2.0, 3 => 12.0, 4 => 24.0, _ => 720.0 };
    let iterations = steps + if order == 3 || order == 5 { 1 } else { 0 };
    let mut count = order;
    for _ in 0..iterations {
        let mut weighted = 0.0;
        for offset in 0..order {
            let index = count - 1 - offset;
            weighted += coefficients[offset] as f64 * (x[index] + y[index]);
        }
        y[count] = y[count - 1] + (0.25 / denominator) * weighted;
        x[count] = x[count - 1] + 0.25;
        count += 1;
    }
    let mut encoded = [0u8; 256];
    let mut position = 0usize;
    for i in 0..count {
        if i > 0 { encoded[position] = b','; position += 1; }
        position = append_integer((y[i] * 1000000.0) as i64, &mut encoded, position);
    }
    if output.is_null() || output_capacity < position { return -2; }
    std::ptr::copy_nonoverlapping(encoded.as_ptr(), output, position);
    position as i64
}

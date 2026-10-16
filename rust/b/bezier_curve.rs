const MAX_POINTS: usize = 16;

fn integer_power(base: f64, exponent: usize) -> f64 {
    let mut result = 1.0;
    for _ in 0..exponent { result *= base; }
    result
}

fn choose(n: usize, k_input: usize) -> u64 {
    let k = k_input.min(n - k_input);
    let mut result = 1u64;
    for index in 1..=k { result = result * (n - k + index) as u64 / index as u64; }
    result
}

fn round_scaled(value: f64) -> i64 {
    let scaled = value * 1_000_000.0;
    if scaled >= 0.0 { (scaled + 0.5) as i64 } else { (scaled - 0.5) as i64 }
}

unsafe fn write_i64_le(output: *mut u8, offset: usize, value: i64) {
    for (byte, value_byte) in value.to_le_bytes().iter().enumerate() {
        *output.add(offset + byte) = *value_byte;
    }
}

#[no_mangle]
pub unsafe extern "C" fn bezier_curve(values: *const i64, length: usize,
                                         output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length < 4 || length > 34 { return -1; }
    let point_count_value = *values;
    let parameter_q = *values.add(1);
    if !(1..=MAX_POINTS as i64).contains(&point_count_value) || !(0..=1_000_000).contains(&parameter_q) { return -1; }
    let point_count = point_count_value as usize;
    if length != 2 + 2 * point_count { return -1; }
    for index in 2..length {
        let value = *values.add(index);
        if !(-1_000_000..=1_000_000).contains(&value) { return -1; }
    }
    if output.is_null() || output_capacity < 32 { return -2; }

    let degree = point_count - 1;
    let t = parameter_q as f64 / 1_000_000.0;
    let (mut x, mut y, mut dx, mut dy) = (0.0, 0.0, 0.0, 0.0);
    for index in 0..point_count {
        let weight = choose(degree, index) as f64
            * integer_power(1.0 - t, degree - index) * integer_power(t, index);
        x += weight * *values.add(2 + 2 * index) as f64;
        y += weight * *values.add(3 + 2 * index) as f64;
    }
    for index in 0..degree {
        let weight = degree as f64 * choose(degree - 1, index) as f64
            * integer_power(1.0 - t, degree - 1 - index) * integer_power(t, index);
        dx += weight * (*values.add(4 + 2 * index) - *values.add(2 + 2 * index)) as f64;
        dy += weight * (*values.add(5 + 2 * index) - *values.add(3 + 2 * index)) as f64;
    }
    write_i64_le(output, 0, round_scaled(x));
    write_i64_le(output, 8, round_scaled(y));
    write_i64_le(output, 16, round_scaled(dx));
    write_i64_le(output, 24, round_scaled(dy));
    32
}

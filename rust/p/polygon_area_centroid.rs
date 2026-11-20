const MAX_VERTICES: usize = 16;
const MAX_PARSEABLE_LENGTH: usize = 34;
const SCALE: i64 = 1_000_000;

fn rounded_micro(numerator: i64, denominator: i64) -> i64 {
    let (numerator, denominator) = if denominator < 0 {
        (-numerator, -denominator)
    } else {
        (numerator, denominator)
    };
    let sign = if numerator < 0 { -1 } else { 1 };
    let scaled = numerator.unsigned_abs() * SCALE as u64;
    let divisor = denominator as u64;
    let mut quotient = scaled / divisor;
    if 2 * (scaled % divisor) >= divisor { quotient += 1; }
    sign * quotient as i64
}

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn polygon_area_centroid(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 7 || length > MAX_PARSEABLE_LENGTH { return -1; }
    let count_value = *input;
    if !(3..=MAX_VERTICES as i64).contains(&count_value) { return -1; }
    let count = count_value as usize;
    if length != 1 + 2 * count { return -1; }

    let mut xs = [0_i64; MAX_VERTICES];
    let mut ys = [0_i64; MAX_VERTICES];
    for i in 0..count {
        let x = *input.add(1 + 2 * i);
        let y = *input.add(2 + 2 * i);
        if !(-50..=50).contains(&x) || !(-50..=50).contains(&y) { return -1; }
        for j in 0..i { if xs[j] == x && ys[j] == y { return -1; } }
        xs[i] = x;
        ys[i] = y;
    }

    let mut twice_area = 0_i64;
    for i in 0..count {
        let next = (i + 1) % count;
        twice_area += xs[i] * ys[next] - xs[next] * ys[i];
    }
    if twice_area == 0 { return -1; }
    let orientation = if twice_area > 0 { 1 } else { -1 };
    for i in 0..count {
        let next = (i + 1) % count;
        for j in 0..count {
            if j == i || j == next { continue; }
            let side = (xs[next] - xs[i]) * (ys[j] - ys[i])
                - (ys[next] - ys[i]) * (xs[j] - xs[i]);
            if side * orientation <= 0 { return -1; }
        }
    }

    let mut numerator_x = 0_i64;
    let mut numerator_y = 0_i64;
    for i in 0..count {
        let next = (i + 1) % count;
        let cross = xs[i] * ys[next] - xs[next] * ys[i];
        numerator_x += (xs[i] + xs[next]) * cross;
        numerator_y += (ys[i] + ys[next]) * cross;
    }
    let x_micro = rounded_micro(numerator_x, 3 * twice_area);
    let y_micro = rounded_micro(numerator_y, 3 * twice_area);
    if output.is_null() || capacity < 16 { return -2; }
    let bytes = std::slice::from_raw_parts_mut(output, 16);
    store_i64_le(bytes, 0, x_micro);
    store_i64_le(bytes, 8, y_micro);
    16
}

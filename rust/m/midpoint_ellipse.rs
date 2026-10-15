fn ellipse_point_count(a: i64, b: i64) -> usize {
    if a == 0 {
        return (2 * b + 1) as usize;
    }
    if b == 0 {
        return (2 * a + 1) as usize;
    }
    let aa = a * a;
    let bb = b * b;
    let mut x = 0_i64;
    let mut y = b;
    let mut dx = 2 * bb * x;
    let mut dy = 2 * aa * y;
    let mut d1 = bb as f64 - (aa * b) as f64 + 0.25 * aa as f64;
    let mut count = 0_usize;
    while dx < dy {
        count += 4;
        if d1 < 0.0 {
            x += 1;
            dx += 2 * bb;
            d1 += (dx + bb) as f64;
        } else {
            x += 1;
            y -= 1;
            dx += 2 * bb;
            dy -= 2 * aa;
            d1 += (dx - dy + bb) as f64;
        }
    }
    let mut d2 = bb as f64 * (x as f64 + 0.5) * (x as f64 + 0.5)
        + aa as f64 * (y - 1) as f64 * (y - 1) as f64
        - (aa * bb) as f64;
    while y >= 0 {
        count += 4;
        if d2 > 0.0 {
            y -= 1;
            dy -= 2 * aa;
            d2 += (aa - dy) as f64;
        } else {
            y -= 1;
            x += 1;
            dx += 2 * bb;
            dy -= 2 * aa;
            d2 += (dx - dy + aa) as f64;
        }
    }
    count
}

unsafe fn write_point(output: *mut u8, point_index: usize, x: i64, y: i64) {
    let x_bytes = (x as i32).to_le_bytes();
    let y_bytes = (y as i32).to_le_bytes();
    let byte_index = point_index * 8;
    for byte in 0..4 {
        *output.add(byte_index + byte) = x_bytes[byte];
        *output.add(byte_index + 4 + byte) = y_bytes[byte];
    }
}

unsafe fn emit_quadrant(
    output: *mut u8,
    point_index: usize,
    center_x: i64,
    center_y: i64,
    x: i64,
    y: i64,
) {
    write_point(output, point_index, center_x + x, center_y + y);
    write_point(output, point_index + 1, center_x - x, center_y + y);
    write_point(output, point_index + 2, center_x + x, center_y - y);
    write_point(output, point_index + 3, center_x - x, center_y - y);
}

#[no_mangle]
pub unsafe extern "C" fn midpoint_ellipse(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if length != 4 || values.is_null() {
        return -1;
    }
    let center_x = *values;
    let center_y = *values.add(1);
    let a = *values.add(2);
    let b = *values.add(3);
    if !(-10_000..=10_000).contains(&center_x)
        || !(-10_000..=10_000).contains(&center_y)
        || !(0..=100).contains(&a)
        || !(0..=100).contains(&b)
    {
        return -1;
    }

    let count = if a == 0 && b == 0 {
        1
    } else {
        ellipse_point_count(a, b)
    };
    if output.is_null() || output_capacity < count * 8 {
        return -2;
    }
    if a == 0 && b == 0 {
        write_point(output, 0, center_x, center_y);
        return 1;
    }
    if a == 0 {
        for offset in 0..count {
            write_point(output, offset, center_x, center_y - b + offset as i64);
        }
        return count as i64;
    }
    if b == 0 {
        for offset in 0..count {
            write_point(output, offset, center_x - a + offset as i64, center_y);
        }
        return count as i64;
    }

    let aa = a * a;
    let bb = b * b;
    let mut x = 0_i64;
    let mut y = b;
    let mut dx = 2 * bb * x;
    let mut dy = 2 * aa * y;
    let mut d1 = bb as f64 - (aa * b) as f64 + 0.25 * aa as f64;
    let mut point_index = 0;
    while dx < dy {
        emit_quadrant(output, point_index, center_x, center_y, x, y);
        point_index += 4;
        if d1 < 0.0 {
            x += 1;
            dx += 2 * bb;
            d1 += (dx + bb) as f64;
        } else {
            x += 1;
            y -= 1;
            dx += 2 * bb;
            dy -= 2 * aa;
            d1 += (dx - dy + bb) as f64;
        }
    }
    let mut d2 = bb as f64 * (x as f64 + 0.5) * (x as f64 + 0.5)
        + aa as f64 * (y - 1) as f64 * (y - 1) as f64
        - (aa * bb) as f64;
    while y >= 0 {
        emit_quadrant(output, point_index, center_x, center_y, x, y);
        point_index += 4;
        if d2 > 0.0 {
            y -= 1;
            dy -= 2 * aa;
            d2 += (aa - dy) as f64;
        } else {
            y -= 1;
            x += 1;
            dx += 2 * bb;
            dy -= 2 * aa;
            d2 += (dx - dy + aa) as f64;
        }
    }
    count as i64
}

unsafe fn write_point(output: *mut u8, point_index: usize, x: i64, y: i64) {
    let x_bytes = (x as i32).to_le_bytes();
    let y_bytes = (y as i32).to_le_bytes();
    let byte_index = point_index * 8;
    for byte in 0..4 {
        *output.add(byte_index + byte) = x_bytes[byte];
        *output.add(byte_index + 4 + byte) = y_bytes[byte];
    }
}

#[no_mangle]
pub unsafe extern "C" fn bresenham_line(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if length != 4 || values.is_null() {
        return -1;
    }
    let x0 = *values;
    let y0 = *values.add(1);
    let x1 = *values.add(2);
    let y1 = *values.add(3);
    if !(-1_000_000..=1_000_000).contains(&x0)
        || !(-1_000_000..=1_000_000).contains(&y0)
        || !(-1_000_000..=1_000_000).contains(&x1)
        || !(-1_000_000..=1_000_000).contains(&y1)
    {
        return -1;
    }

    let dx = (x1 - x0).abs();
    let abs_dy = (y1 - y0).abs();
    let steps = dx.max(abs_dy);
    if steps > 4_096 {
        return -1;
    }
    let count = steps + 1;
    if output.is_null() || output_capacity < (count * 8) as usize {
        return -2;
    }

    let mut x = x0;
    let mut y = y0;
    let sx = if x0 < x1 { 1 } else { -1 };
    let sy = if y0 < y1 { 1 } else { -1 };
    let dy = -abs_dy;
    let mut error = dx + dy;
    let mut point_index = 0_usize;
    loop {
        write_point(output, point_index, x, y);
        point_index += 1;
        if x == x1 && y == y1 {
            break;
        }
        let doubled_error = 2 * error;
        if doubled_error > dy {
            error += dy;
            x += sx;
        }
        if doubled_error < dx {
            error += dx;
            y += sy;
        }
    }
    count
}

fn plotted_point_count(radius: i64) -> usize {
    if radius == 0 {
        return 1;
    }
    let mut x = radius;
    let mut y = 0_i64;
    let mut decision = 1 - radius;
    let mut count = 8_usize;
    while x > y {
        y += 1;
        if decision <= 0 {
            decision += 2 * y + 1;
        } else {
            x -= 1;
            decision += 2 * y - 2 * x + 1;
        }
        count += 8;
    }
    count
}

unsafe fn append_symmetric_points(
    output: *mut u8,
    mut point_index: usize,
    center_x: i64,
    center_y: i64,
    x: i64,
    y: i64,
) -> usize {
    let offsets = [(x, y), (-x, y), (x, -y), (-x, -y), (y, x), (-y, x), (y, -x), (-y, -x)];
    for (offset_x, offset_y) in offsets {
        let point_x = (center_x + offset_x) as i32;
        let point_y = (center_y + offset_y) as i32;
        let x_bytes = point_x.to_le_bytes();
        let y_bytes = point_y.to_le_bytes();
        let byte_index = point_index * 8;
        for byte in 0..4 {
            *output.add(byte_index + byte) = x_bytes[byte];
            *output.add(byte_index + 4 + byte) = y_bytes[byte];
        }
        point_index += 1;
    }
    point_index
}

#[no_mangle]
pub unsafe extern "C" fn midpoint_circle(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if length != 3 || values.is_null() {
        return -1;
    }
    let center_x = *values;
    let center_y = *values.add(1);
    let radius = *values.add(2);
    if !(-10_000..=10_000).contains(&center_x)
        || !(-10_000..=10_000).contains(&center_y)
        || !(0..=1_000).contains(&radius)
    {
        return -1;
    }

    let count = plotted_point_count(radius);
    if output.is_null() || output_capacity < count * 8 {
        return -2;
    }
    if radius == 0 {
        let x_bytes = (center_x as i32).to_le_bytes();
        let y_bytes = (center_y as i32).to_le_bytes();
        for byte in 0..4 {
            *output.add(byte) = x_bytes[byte];
            *output.add(4 + byte) = y_bytes[byte];
        }
        return 1;
    }

    let mut point_index = 0;
    let mut x = radius;
    let mut y = 0_i64;
    let mut decision = 1 - radius;
    point_index = append_symmetric_points(output, point_index, center_x, center_y, x, y);
    while x > y {
        y += 1;
        if decision <= 0 {
            decision += 2 * y + 1;
        } else {
            x -= 1;
            decision += 2 * y - 2 * x + 1;
        }
        point_index = append_symmetric_points(output, point_index, center_x, center_y, x, y);
    }
    point_index as i64
}

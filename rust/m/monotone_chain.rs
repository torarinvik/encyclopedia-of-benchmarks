const MAX_POINT_COUNT: usize = 64;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 130;
const MAX_COORDINATE: i64 = 1_000_000;

#[derive(Clone, Copy)]
struct Point { x: i32, y: i32 }

fn point_less(a: Point, b: Point) -> bool {
    a.x < b.x || (a.x == b.x && a.y < b.y)
}

fn cross(origin: Point, first: Point, second: Point) -> i64 {
    let dx1 = i64::from(first.x) - i64::from(origin.x);
    let dy1 = i64::from(first.y) - i64::from(origin.y);
    let dx2 = i64::from(second.x) - i64::from(origin.x);
    let dy2 = i64::from(second.y) - i64::from(origin.y);
    dx1 * dy2 - dy1 * dx2
}

fn store_i32_le(output: *mut u8, offset: usize, value: i32) {
    let bits = value as u32;
    for byte in 0..4 {
        unsafe { *output.add(offset + byte) = (bits >> (byte * 8)) as u8; }
    }
}

/// Bounded Andrew monotone-chain convex hull.
#[no_mangle]
pub unsafe extern "C" fn monotone_chain(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let raw_count = input[0];
    if raw_count < 0 || raw_count > MAX_POINT_COUNT as i64 { return -1; }
    let count = raw_count as usize;
    if length != 1 + 2 * count { return -1; }

    let mut points = [Point { x: 0, y: 0 }; MAX_POINT_COUNT];
    let mut scratch = [Point { x: 0, y: 0 }; MAX_POINT_COUNT];
    let mut hull = [Point { x: 0, y: 0 }; 2 * MAX_POINT_COUNT];
    for index in 0..count {
        let x = input[1 + 2 * index];
        let y = input[2 + 2 * index];
        if x < -MAX_COORDINATE || x > MAX_COORDINATE || y < -MAX_COORDINATE || y > MAX_COORDINATE {
            return -1;
        }
        points[index] = Point { x: x as i32, y: y as i32 };
    }

    let mut width = 1;
    while width < count {
        let mut start = 0;
        while start < count {
            let middle = (start + width).min(count);
            let end = (middle + width).min(count);
            let mut left = start;
            let mut right = middle;
            let mut destination = start;
            while left < middle && right < end {
                if point_less(points[right], points[left]) {
                    scratch[destination] = points[right];
                    right += 1;
                } else {
                    scratch[destination] = points[left];
                    left += 1;
                }
                destination += 1;
            }
            while left < middle {
                scratch[destination] = points[left];
                left += 1;
                destination += 1;
            }
            while right < end {
                scratch[destination] = points[right];
                right += 1;
                destination += 1;
            }
            start += 2 * width;
        }
        points[..count].copy_from_slice(&scratch[..count]);
        width *= 2;
    }

    let mut unique_count = 0;
    for index in 0..count {
        if unique_count == 0 || points[index].x != points[unique_count - 1].x ||
            points[index].y != points[unique_count - 1].y {
            points[unique_count] = points[index];
            unique_count += 1;
        }
    }

    let mut hull_count = 0;
    if unique_count == 1 {
        hull[hull_count] = points[0];
        hull_count += 1;
    } else if unique_count > 1 {
        for index in 0..unique_count {
            while hull_count >= 2 && cross(hull[hull_count - 2], hull[hull_count - 1], points[index]) <= 0 {
                hull_count -= 1;
            }
            hull[hull_count] = points[index];
            hull_count += 1;
        }
        let lower_count = hull_count;
        let mut index = unique_count - 1;
        while index > 0 {
            index -= 1;
            while hull_count > lower_count && cross(hull[hull_count - 2], hull[hull_count - 1], points[index]) <= 0 {
                hull_count -= 1;
            }
            hull[hull_count] = points[index];
            hull_count += 1;
        }
        hull_count -= 1;
    }

    let byte_count = 8 * hull_count;
    if output.is_null() || capacity < byte_count { return -2; }
    for index in 0..hull_count {
        store_i32_le(output, 8 * index, hull[index].x);
        store_i32_le(output, 8 * index + 4, hull[index].y);
    }
    byte_count as i64
}

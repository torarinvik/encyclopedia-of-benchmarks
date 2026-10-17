const MAX_POINTS: usize = 64;
const MAX_INPUT_LENGTH: usize = 130;
const MAX_OUTPUT_BYTES: usize = 513;

#[derive(Clone, Copy)]
struct Point { x: i32, y: i32 }

fn dominates(left: Point, right: Point) -> bool {
    (left.x < right.x && left.y <= right.y)
        || (left.x <= right.x && left.y < right.y)
}

fn produce_skyline(points: &[Point], output: &mut [Point]) -> usize {
    if points.len() == 1 {
        output[0] = points[0];
        return 1;
    }
    if points.len() == 2 {
        if dominates(points[0], points[1]) {
            output[0] = points[0];
            return 1;
        }
        if dominates(points[1], points[0]) {
            output[0] = points[1];
            return 1;
        }
        output[..2].copy_from_slice(points);
        return 2;
    }

    let middle = points.len() / 2;
    let mut left = [Point { x: 0, y: 0 }; MAX_POINTS];
    let mut right = [Point { x: 0, y: 0 }; MAX_POINTS];
    let mut left_count = produce_skyline(&points[..middle], &mut left);
    let mut right_count = produce_skyline(&points[middle..], &mut right);

    let mut index = 0;
    while index + 1 < left_count {
        if left[index].x == left[index + 1].x && left[index].y > left[index + 1].y {
            left.copy_within(index + 1..left_count, index);
            left_count -= 1;
            if index > 0 { index -= 1; }
        } else {
            index += 1;
        }
    }

    let mut minimum_y = left[0].y;
    for point in left.iter().take(left_count).skip(1) {
        if minimum_y > point.y {
            minimum_y = point.y;
            if minimum_y == 1 { break; }
        }
    }

    index = 0;
    while index < right_count {
        if right[index].y >= minimum_y {
            right.copy_within(index + 1..right_count, index);
            right_count -= 1;
        } else {
            index += 1;
        }
    }
    output[..left_count].copy_from_slice(&left[..left_count]);
    output[left_count..left_count + right_count].copy_from_slice(&right[..right_count]);
    left_count + right_count
}

/// Construct the pinned divide-and-conquer skyline for points ordered by x.
#[no_mangle]
pub unsafe extern "C" fn skyline_algorithm(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    let count_value = values[0];
    if !(1..=MAX_POINTS as i64).contains(&count_value) {
        return -1;
    }
    let count = count_value as usize;
    if input_length != 1 + 2 * count {
        return -1;
    }

    let mut points = [Point { x: 0, y: 0 }; MAX_POINTS];
    let mut previous_x: Option<i32> = None;
    for index in 0..count {
        let x = values[1 + 2 * index];
        let y = values[2 + 2 * index];
        if x < i32::MIN as i64 || x > i32::MAX as i64
            || y < 1 || y > i32::MAX as i64
        {
            return -1;
        }
        let x = x as i32;
        if let Some(prior) = previous_x {
            if x <= prior { return -1; }
        }
        previous_x = Some(x);
        points[index] = Point { x, y: y as i32 };
    }

    let mut skyline = [Point { x: 0, y: 0 }; MAX_POINTS];
    let skyline_count = produce_skyline(&points[..count], &mut skyline);
    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    staged[0] = skyline_count as u8;
    for (index, point) in skyline.iter().take(skyline_count).enumerate() {
        let offset = 1 + 8 * index;
        staged[offset..offset + 4].copy_from_slice(&point.x.to_le_bytes());
        staged[offset + 4..offset + 8].copy_from_slice(&point.y.to_le_bytes());
    }
    let written = 1 + 8 * skyline_count;
    if output.is_null() || output_capacity < written { return -2; }
    unsafe { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, written); }
    written as i64
}

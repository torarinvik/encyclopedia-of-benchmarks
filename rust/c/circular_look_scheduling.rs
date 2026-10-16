const MAX_REQUESTS: usize = 64;
const MAX_CYLINDER_COUNT: i64 = 128;

fn sort_ascending(items: &mut [i64; MAX_REQUESTS], count: usize) {
    for index in 1..count {
        let value = items[index];
        let mut position = index;
        while position > 0 && items[position - 1] > value {
            items[position] = items[position - 1];
            position -= 1;
        }
        items[position] = value;
    }
}

#[no_mangle]
pub unsafe extern "C" fn circular_look_scheduling(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 4 || length > 4 + MAX_REQUESTS { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let max_cylinder = input[0];
    let start = input[1];
    let moving_up = input[2];
    let request_count = input[3];
    if !(1..=MAX_CYLINDER_COUNT).contains(&max_cylinder) || start < 0 || start >= max_cylinder ||
        (moving_up != 0 && moving_up != 1) || !(0..=MAX_REQUESTS as i64).contains(&request_count) ||
        length != 4 + request_count as usize { return -1; }

    let mut up = [0i64; MAX_REQUESTS];
    let mut down = [0i64; MAX_REQUESTS];
    let mut up_count = 0usize;
    let mut down_count = 0usize;
    for &request in &input[4..] {
        if !(-128..=255).contains(&request) { return -1; }
        if request < 0 || request >= max_cylinder || request == start { continue; }
        if request > start {
            up[up_count] = request;
            up_count += 1;
        } else {
            down[down_count] = request;
            down_count += 1;
        }
    }
    sort_ascending(&mut up, up_count);
    sort_ascending(&mut down, down_count);

    let output_count = up_count + down_count;
    if capacity < output_count || (output_count > 0 && output.is_null()) { return -2; }
    if output_count == 0 { return 0; }
    let result = std::slice::from_raw_parts_mut(output, output_count);
    let mut position = 0;
    if moving_up == 1 {
        for &value in &up[..up_count] { result[position] = value as u8; position += 1; }
        for &value in &down[..down_count] { result[position] = value as u8; position += 1; }
    } else {
        for index in (0..down_count).rev() { result[position] = down[index] as u8; position += 1; }
        for index in (0..up_count).rev() { result[position] = up[index] as u8; position += 1; }
    }
    output_count as i64
}

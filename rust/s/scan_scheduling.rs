const MAX_REQUESTS: usize = 64;
const MAX_OUTPUT_VALUES: usize = 65;

fn sort_ascending(values: &mut [i32; MAX_REQUESTS], count: usize) {
    for i in 1..count {
        let value = values[i];
        let mut position = i;
        while position > 0 && values[position - 1] > value {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[position] = value;
    }
}

fn put_i32_le(output: &mut [u8], offset: usize, value: i32) {
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn scan_scheduling(
    input: *const i32, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > 68 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let disk_size = values[0];
    let head = values[1];
    let direction = values[2];
    let request_count = values[3];
    if !(1..=256).contains(&disk_size) || head < 0 || head >= disk_size ||
        (direction != 0 && direction != 1) || !(0..=MAX_REQUESTS as i32).contains(&request_count) ||
        length != 4 + request_count as usize { return -1; }

    let mut left = [0i32; MAX_REQUESTS];
    let mut right = [0i32; MAX_REQUESTS];
    let mut left_count = 0usize;
    let mut right_count = 0usize;
    for &request in &values[4..] {
        if request < 0 || request >= disk_size { return -1; }
        if request < head {
            left[left_count] = request;
            left_count += 1;
        } else {
            right[right_count] = request;
            right_count += 1;
        }
    }
    sort_ascending(&mut left, left_count);
    sort_ascending(&mut right, right_count);

    let mut ordered = [0i32; MAX_OUTPUT_VALUES];
    let mut count = 0usize;
    if request_count > 0 {
        if direction == 1 {
            for &value in &right[..right_count] { ordered[count] = value; count += 1; }
            ordered[count] = disk_size - 1;
            count += 1;
            for i in (0..left_count).rev() { ordered[count] = left[i]; count += 1; }
        } else {
            for i in (0..left_count).rev() { ordered[count] = left[i]; count += 1; }
            ordered[count] = 0;
            count += 1;
            for &value in &right[..right_count] { ordered[count] = value; count += 1; }
        }
    }
    let bytes = count * 4;
    if output.is_null() || capacity < bytes { return -2; }
    let mut buffer = [0u8; MAX_OUTPUT_VALUES * 4];
    for i in 0..count { put_i32_le(&mut buffer, i * 4, ordered[i]); }
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, bytes);
    bytes as i64
}

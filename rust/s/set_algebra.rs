const MAX_SET_SIZE: usize = 64;
const MAX_RESULT_SIZE: usize = 2 * MAX_SET_SIZE;
const MAX_INPUT_LENGTH: usize = 4 + 2 * MAX_SET_SIZE;

fn contains(values: &[i64], target: i64) -> bool { values.iter().any(|&value| value == target) }
fn is_subset(left: &[i64], right: &[i64]) -> bool { left.iter().all(|&value| contains(right, value)) }
fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn set_algebra(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    let operation = values[0];
    let left_raw = values[1];
    let right_raw = values[2];
    let query_key = values[3];
    if !(0..=8).contains(&operation) || !(0..=MAX_SET_SIZE as i64).contains(&left_raw) || !(0..=MAX_SET_SIZE as i64).contains(&right_raw) || !(-1_000_000..=1_000_000).contains(&query_key) { return -1; }
    let left_length = left_raw as usize;
    let right_length = right_raw as usize;
    if length != 4 + left_length + right_length { return -1; }

    let mut left = [0i64; MAX_SET_SIZE];
    let mut right = [0i64; MAX_SET_SIZE];
    let mut result = [0i64; MAX_RESULT_SIZE];
    let (mut left_count, mut right_count, mut result_count) = (0usize, 0usize, 0usize);
    for i in 0..left_length {
        let value = values[4 + i];
        if !(-1_000_000..=1_000_000).contains(&value) { return -1; }
        if !contains(&left[..left_count], value) { left[left_count] = value; left_count += 1; }
    }
    for i in 0..right_length {
        let value = values[4 + left_length + i];
        if !(-1_000_000..=1_000_000).contains(&value) { return -1; }
        if !contains(&right[..right_count], value) { right[right_count] = value; right_count += 1; }
    }
    let a = &left[..left_count];
    let b = &right[..right_count];

    if operation == 0 { result[0] = i64::from(contains(a, query_key)); result_count = 1; }
    else if operation == 1 { result[0] = i64::from(is_subset(a, b)); result_count = 1; }
    else if operation == 2 { result[0] = i64::from(a.len() < b.len() && is_subset(a, b)); result_count = 1; }
    else if operation == 3 { result[0] = i64::from(is_subset(b, a)); result_count = 1; }
    else if operation == 4 { result[0] = i64::from(b.len() < a.len() && is_subset(b, a)); result_count = 1; }
    else if operation == 5 {
        for &value in a { result[result_count] = value; result_count += 1; }
        for &value in b { if !contains(a, value) { result[result_count] = value; result_count += 1; } }
    } else if operation == 6 {
        for &value in a { if contains(b, value) { result[result_count] = value; result_count += 1; } }
    } else if operation == 7 {
        for &value in a { if !contains(b, value) { result[result_count] = value; result_count += 1; } }
    } else {
        for &value in a { if !contains(b, value) { result[result_count] = value; result_count += 1; } }
        for &value in b { if !contains(a, value) { result[result_count] = value; result_count += 1; } }
    }
    result[..result_count].sort_unstable();

    let output_bytes = result_count * 8;
    if capacity < output_bytes || (output_bytes > 0 && output.is_null()) { return -2; }
    if output_bytes > 0 {
        let target = unsafe { core::slice::from_raw_parts_mut(output, output_bytes) };
        for i in 0..result_count { put_i64_le(target, i * 8, result[i]); }
    }
    output_bytes as i64
}

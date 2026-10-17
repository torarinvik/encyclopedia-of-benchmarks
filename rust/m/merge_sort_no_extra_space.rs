const MAX_LENGTH: usize = 256;

fn read_i32_le(buffer: &[u8], index: usize) -> i32 {
    let offset = index * 4;
    i32::from_le_bytes(buffer[offset..offset + 4].try_into().unwrap())
}

fn write_i32_le(buffer: &mut [u8], index: usize, value: i32) {
    let offset = index * 4;
    buffer[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

fn merge(buffer: &mut [u8], start: usize, middle: usize, end: usize, max_element: i32) {
    let (mut i, mut j, mut k) = (start, middle + 1, start);
    while i <= middle && j <= end {
        let left = read_i32_le(buffer, i) % max_element;
        let right = read_i32_le(buffer, j) % max_element;
        let current = read_i32_le(buffer, k);
        if left <= right {
            write_i32_le(buffer, k, current + left * max_element);
            i += 1;
        } else {
            write_i32_le(buffer, k, current + right * max_element);
            j += 1;
        }
        k += 1;
    }
    while i <= middle {
        let current = read_i32_le(buffer, k);
        let next = read_i32_le(buffer, i) % max_element;
        write_i32_le(buffer, k, current + next * max_element);
        i += 1;
        k += 1;
    }
    while j <= end {
        let current = read_i32_le(buffer, k);
        let next = read_i32_le(buffer, j) % max_element;
        write_i32_le(buffer, k, current + next * max_element);
        j += 1;
        k += 1;
    }
    for index in start..=end {
        let value = read_i32_le(buffer, index) / max_element;
        write_i32_le(buffer, index, value);
    }
}

fn merge_sort(buffer: &mut [u8], start: usize, end: usize, max_element: i32) {
    if start >= end { return; }
    let middle = start + (end - start) / 2;
    merge_sort(buffer, start, middle, max_element);
    merge_sort(buffer, middle + 1, end, max_element);
    merge(buffer, start, middle, end, max_element);
}

#[no_mangle]
pub unsafe extern "C" fn merge_sort_no_extra_space(
    values: *const i32,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length > MAX_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let mut max_value = 0i32;
    for &value in input {
        if !(0..=32767).contains(&value) { return -1; }
        max_value = max_value.max(value);
    }
    let output_bytes = length * 4;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    let buffer = std::slice::from_raw_parts_mut(output, output_bytes);
    for (index, &value) in input.iter().enumerate() { write_i32_le(buffer, index, value); }
    if length > 1 { merge_sort(buffer, 0, length - 1, max_value + 1); }
    output_bytes as i64
}

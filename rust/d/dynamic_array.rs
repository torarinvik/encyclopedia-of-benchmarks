const MAX_OPERATIONS: usize = 128;
const MAX_ELEMENTS: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 3 * MAX_OPERATIONS;

fn write_i64_le(output: *mut u8, word_index: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for byte in 0..8 {
        unsafe { *output.add(word_index * 8 + byte) = bytes[byte]; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn dynamic_array(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let operation_count_value = values[0];
    if operation_count_value < 0 || operation_count_value > MAX_OPERATIONS as i64 { return -1; }

    let mut first = [0_i64; MAX_ELEMENTS];
    let mut second = [0_i64; MAX_ELEMENTS];
    let mut query_results = [0_i64; MAX_OPERATIONS];
    let mut active_first = true;
    let mut size = 0_usize;
    let mut capacity = 16_usize;
    let mut cursor = 1_usize;
    let mut query_count = 0_usize;

    for _ in 0..operation_count_value as usize {
        if cursor >= length { return -1; }
        let operation = values[cursor];
        cursor += 1;
        if operation == 0 {
            if cursor >= length || size >= MAX_ELEMENTS { return -1; }
            let value = values[cursor];
            cursor += 1;
            if size == capacity {
                if active_first {
                    for index in 0..size { second[index] = first[index]; }
                    active_first = false;
                } else {
                    for index in 0..size { first[index] = second[index]; }
                    active_first = true;
                }
                capacity *= 2;
            }
            if active_first { first[size] = value; } else { second[size] = value; }
            size += 1;
        } else if operation == 1 {
            if cursor + 1 >= length { return -1; }
            let index_value = values[cursor];
            let value = values[cursor + 1];
            cursor += 2;
            if index_value < 0 || index_value as u64 >= size as u64 { return -1; }
            let index = index_value as usize;
            if active_first { first[index] = value; } else { second[index] = value; }
        } else if operation == 2 {
            if cursor >= length || query_count >= MAX_OPERATIONS { return -1; }
            let index_value = values[cursor];
            cursor += 1;
            if index_value < 0 || index_value as u64 >= size as u64 { return -1; }
            let index = index_value as usize;
            query_results[query_count] = if active_first { first[index] } else { second[index] };
            query_count += 1;
        } else if operation == 3 {
            if query_count >= MAX_OPERATIONS { return -1; }
            query_results[query_count] = size as i64;
            query_count += 1;
        } else {
            return -1;
        }
    }
    if cursor != length { return -1; }

    let output_words = 2 + query_count + size;
    let output_bytes = output_words * 8;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    write_i64_le(output, 0, query_count as i64);
    for index in 0..query_count { write_i64_le(output, index + 1, query_results[index]); }
    write_i64_le(output, query_count + 1, size as i64);
    for index in 0..size {
        let value = if active_first { first[index] } else { second[index] };
        write_i64_le(output, query_count + 2 + index, value);
    }
    output_words as i64
}

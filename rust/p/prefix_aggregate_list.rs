const MAX_INITIAL_VALUES: usize = 64;
const MAX_OPERATIONS: usize = 64;
const MAX_LIVE_VALUES: usize = 128;
const MAX_INPUT_LENGTH: usize = 258;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 260;
const MAX_OUTPUT_BYTES: usize = 512;
const MAX_VALUE: i64 = 1_000_000;

#[no_mangle]
pub unsafe extern "C" fn prefix_aggregate_list(
    input_pointer: *const i64,
    length: usize,
    output_pointer: *mut u8,
    capacity: usize,
) -> i64 {
    if input_pointer.is_null() || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input_pointer, length) };
    let initial_count_value = input[0];
    if !(1..=MAX_INITIAL_VALUES as i64).contains(&initial_count_value) { return -1; }
    let initial_count = initial_count_value as usize;
    if length < initial_count + 2 { return -1; }

    let mut prefix = [0i64; MAX_LIVE_VALUES];
    for index in 0..initial_count {
        let value = input[1 + index];
        if !(-MAX_VALUE..=MAX_VALUE).contains(&value) { return -1; }
        prefix[index] = value + if index == 0 { 0 } else { prefix[index - 1] };
    }

    let operation_count_value = input[1 + initial_count];
    if !(0..=MAX_OPERATIONS as i64).contains(&operation_count_value) { return -1; }
    let operation_count = operation_count_value as usize;
    let mut live_count = initial_count;
    let mut cursor = initial_count + 2;
    let mut query_count = 0usize;
    let mut encoded = [0u8; MAX_OUTPUT_BYTES];

    for _ in 0..operation_count {
        if cursor >= length { return -1; }
        let operation = input[cursor];
        cursor += 1;
        if operation == 0 {
            if cursor >= length || live_count >= MAX_LIVE_VALUES { return -1; }
            let value = input[cursor];
            cursor += 1;
            if !(-MAX_VALUE..=MAX_VALUE).contains(&value) { return -1; }
            prefix[live_count] = prefix[live_count - 1] + value;
            live_count += 1;
        } else if operation == 1 {
            if live_count <= 1 { return -1; }
            live_count -= 1;
        } else if operation == 2 {
            if cursor + 1 >= length { return -1; }
            let range_from = input[cursor];
            let range_to = input[cursor + 1];
            cursor += 2;
            if range_from < 1 || range_to < range_from || range_to > live_count as i64 { return -1; }
            let from_index = range_from as usize;
            let to_index = range_to as usize;
            let query_result = prefix[to_index - 1] -
                               if from_index == 1 { 0 } else { prefix[from_index - 2] };
            let start = 8 * query_count;
            encoded[start..start + 8].copy_from_slice(&query_result.to_le_bytes());
            query_count += 1;
        } else {
            return -1;
        }
    }

    if cursor != length { return -1; }
    let output_bytes = 8 * query_count;
    if output_pointer.is_null() || capacity < output_bytes { return -2; }
    unsafe { std::ptr::copy_nonoverlapping(encoded.as_ptr(), output_pointer, output_bytes); }
    output_bytes as i64
}

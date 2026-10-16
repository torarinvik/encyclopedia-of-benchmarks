const MAX_INSERTS: usize = 128;
const MAX_QUERIES: usize = 64;

fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn bag(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    let insert_count_value = input[0];
    if !(0..=MAX_INSERTS as i64).contains(&insert_count_value) { return -1; }
    let insert_count = insert_count_value as usize;
    if length < insert_count + 2 { return -1; }
    let query_count_value = input[insert_count + 1];
    if !(0..=MAX_QUERIES as i64).contains(&query_count_value) { return -1; }
    let query_count = query_count_value as usize;
    if length != insert_count + query_count + 2 { return -1; }

    if input[1..insert_count + 1].iter().any(|value| *value < i32::MIN as i64 || *value > i32::MAX as i64)
        || input[insert_count + 2..].iter().any(|value| *value < i32::MIN as i64 || *value > i32::MAX as i64) {
        return -1;
    }
    let output_length = (query_count + 2) * 8;
    if output.is_null() || capacity < output_length { return -2; }

    let mut values = [0_i64; MAX_INSERTS];
    let mut distinct_count = 0;
    for value in &input[1..insert_count + 1] {
        let mut node = 0;
        while node < distinct_count && values[node] != *value { node += 1; }
        if node == distinct_count {
            values[node] = *value;
            distinct_count += 1;
        }
    }

    let output = std::slice::from_raw_parts_mut(output, output_length);
    put_i64_le(output, 0, insert_count_value);
    put_i64_le(output, 8, if insert_count == 0 { 1 } else { 0 });
    for query in 0..query_count {
        let target = input[insert_count + query + 2];
        let mut contains = 0;
        for node in 0..distinct_count {
            if values[node] == target { contains = 1; }
        }
        put_i64_le(output, (query + 2) * 8, contains);
    }
    output_length as i64
}

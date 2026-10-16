const OP_LIMIT: usize = 128;
const ITEM_LIMIT: usize = 64;

fn write_word(output: *mut u8, word: usize, value: i64) {
    for (offset, byte) in value.to_le_bytes().iter().enumerate() {
        unsafe { *output.add(word * 8 + offset) = *byte; }
    }
}

/// Execute a bounded dynamic-array trace with capacity ten and doubling growth.
#[no_mangle]
pub unsafe extern "C" fn dynamicarray(input: *const i64, length: usize,
                                      output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > 1 + 3 * OP_LIMIT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > OP_LIMIT as i64 { return -1; }
    let mut a = [0i64; ITEM_LIMIT]; let mut b = [0i64; ITEM_LIMIT];
    let mut queries = [0i64; OP_LIMIT];
    let (mut size, mut capacity, mut cursor, mut query_count, mut active) = (0usize, 0usize, 1usize, 0usize, 0usize);
    for _ in 0..values[0] as usize {
        if cursor >= length { return -1; }
        let op = values[cursor]; cursor += 1;
        if op == 0 {
            if cursor >= length || size >= ITEM_LIMIT { return -1; }
            if size == capacity {
                if active == 0 { b[..size].copy_from_slice(&a[..size]); active = 1; }
                else { a[..size].copy_from_slice(&b[..size]); active = 0; }
                capacity = if capacity == 0 { 10 } else { capacity * 2 };
            }
            if active == 0 { a[size] = values[cursor]; } else { b[size] = values[cursor]; }
            size += 1; cursor += 1;
        } else if op == 1 {
            if cursor + 1 >= length { return -1; }
            let index = values[cursor]; let value = values[cursor + 1]; cursor += 2;
            if index < 0 || index as u64 >= size as u64 { return -1; }
            if active == 0 { a[index as usize] = value; } else { b[index as usize] = value; }
        } else if op == 2 || op == 3 {
            if cursor >= length { return -1; }
            let index = values[cursor]; cursor += 1;
            if index < 0 || index as u64 >= size as u64 { return -1; }
            let index = index as usize;
            if op == 2 {
                if query_count >= OP_LIMIT { return -1; }
                queries[query_count] = if active == 0 { a[index] } else { b[index] };
                query_count += 1;
            } else {
                if active == 0 { a.copy_within(index + 1..size, index); }
                else { b.copy_within(index + 1..size, index); }
                size -= 1;
            }
        } else if (4..=6).contains(&op) {
            if query_count >= OP_LIMIT { return -1; }
            queries[query_count] = if op == 4 { size as i64 } else if op == 5 { capacity as i64 } else { (size == 0) as i64 };
            query_count += 1;
        } else { return -1; }
    }
    if cursor != length { return -1; }
    let words = 3 + query_count + size;
    if output.is_null() || output_capacity < words * 8 { return -2; }
    write_word(output, 0, query_count as i64);
    for i in 0..query_count { write_word(output, i + 1, queries[i]); }
    write_word(output, query_count + 1, size as i64);
    write_word(output, query_count + 2, capacity as i64);
    for i in 0..size { write_word(output, query_count + 3 + i, if active == 0 { a[i] } else { b[i] }); }
    words as i64
}

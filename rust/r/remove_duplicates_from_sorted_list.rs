/// Unlink later nodes with the same value in a sorted indexed list.
const MAX_NODES: usize = 1024;

#[no_mangle]
pub unsafe extern "C" fn remove_duplicates_from_sorted_list(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if length > MAX_NODES || (length != 0 && input.is_null()) { return -1; }
    for index in 0..length {
        let value = *input.add(index);
        if value < i32::MIN as i64 || value > i32::MAX as i64
            || (index != 0 && *input.add(index - 1) > value) { return -1; }
    }
    let mut next_node = [0usize; MAX_NODES + 1];
    for index in 0..length { next_node[index] = index + 1; }
    next_node[length] = length;
    let mut current = 0;
    while current != length && next_node[current] != length {
        let next = next_node[current];
        if *input.add(current) == *input.add(next) { next_node[current] = next_node[next]; }
        else { current = next; }
    }
    let mut survivor_count = 0;
    let mut node = 0;
    while node != length { survivor_count += 1; node = next_node[node]; }
    let output_bytes = survivor_count * 4;
    if output_capacity < output_bytes || (output_bytes != 0 && output.is_null()) { return -2; }
    let mut written = 0;
    node = 0;
    while node != length {
        let bits = *input.add(node) as i32 as u32;
        for byte in 0..4 { *output.add(written * 4 + byte) = (bits >> (byte * 8)) as u8; }
        written += 1;
        node = next_node[node];
    }
    if written != survivor_count { return -1; }
    written as i64
}

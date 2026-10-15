/// Recursively unlink every node in a repeated-value run.
const MAX_NODES: usize = 1024;

unsafe fn remove_duplicate_runs(input: *const i64, next_node: *mut usize,
    node: usize, none: usize) -> usize {
    if node == none { return none; }
    let next = *next_node.add(node);
    if next != none && *input.add(node) == *input.add(next) {
        let duplicate = *input.add(node);
        let mut after_run = next;
        while after_run != none && *input.add(after_run) == duplicate {
            after_run = *next_node.add(after_run);
        }
        return remove_duplicate_runs(input, next_node, after_run, none);
    }
    *next_node.add(node) = remove_duplicate_runs(input, next_node, next, none);
    node
}

#[no_mangle]
pub unsafe extern "C" fn remove_all_duplicates_from_sorted_list(input: *const i64, length: usize,
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
    let head = remove_duplicate_runs(input, next_node.as_mut_ptr(), 0, length);
    let mut survivor_count = 0;
    let mut node = head;
    while node != length { survivor_count += 1; node = next_node[node]; }
    let output_bytes = survivor_count * 4;
    if output_capacity < output_bytes || (output_bytes != 0 && output.is_null()) { return -2; }
    let mut written = 0;
    node = head;
    while node != length {
        let bits = *input.add(node) as i32 as u32;
        for byte in 0..4 { *output.add(written * 4 + byte) = (bits >> (byte * 8)) as u8; }
        written += 1;
        node = next_node[node];
    }
    if written != survivor_count { return -1; }
    written as i64
}

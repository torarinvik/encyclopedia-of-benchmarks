/// Delete the floor(n / 2)-indexed node using the source's fast/slow traversal.
const MAX_NODES: usize = 1024;

#[no_mangle]
pub unsafe extern "C" fn delete_middle_node(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if length > MAX_NODES || (length != 0 && input.is_null()) { return -1; }
    for index in 0..length {
        let value = *input.add(index);
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
    }
    if length <= 1 { return 0; }
    let mut next_node = [length; MAX_NODES + 1];
    for index in 0..length { next_node[index] = index + 1; }
    next_node[length] = length;
    let mut node_count = 0;
    let mut cursor = 0;
    while cursor != length { node_count += 1; cursor = next_node[cursor]; }
    let mut fast = 0;
    let mut slow = 0;
    let mut previous = length;
    while next_node[fast] != length && next_node[next_node[fast]] != length {
        previous = slow;
        slow = next_node[slow];
        fast = next_node[next_node[fast]];
    }
    if node_count % 2 == 0 { previous = slow; slow = next_node[slow]; }
    next_node[previous] = next_node[slow];
    let survivor_count = node_count - 1;
    let output_bytes = survivor_count * 4;
    if output_capacity < output_bytes || (output_bytes != 0 && output.is_null()) { return -2; }
    let mut written = 0;
    let mut node = 0;
    while node != length {
        let bits = *input.add(node) as i32 as u32;
        for byte in 0..4 { *output.add(written * 4 + byte) = (bits >> (byte * 8)) as u8; }
        written += 1;
        node = next_node[node];
    }
    written as i64
}

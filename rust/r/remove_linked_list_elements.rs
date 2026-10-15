/// Recursively unlink matching nodes from an indexed linked-list representation.
const MAX_NODES: usize = 1024;

unsafe fn remove_chain(input: *const i64, next_node: *mut usize, node: usize,
    none: usize, target: i64) -> usize {
    if node == none { return none; }
    let next = *next_node.add(node);
    if *input.add(node + 1) == target {
        return remove_chain(input, next_node, next, none, target);
    }
    *next_node.add(node) = remove_chain(input, next_node, next, none, target);
    node
}

#[no_mangle]
pub unsafe extern "C" fn remove_linked_list_elements(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length == 0 || length > MAX_NODES + 1 { return -1; }
    let target = *input;
    if target < i32::MIN as i64 || target > i32::MAX as i64 { return -1; }
    let node_count = length - 1;
    let mut next_node = [node_count; MAX_NODES + 1];
    for index in 0..node_count {
        let value = *input.add(index + 1);
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        next_node[index] = index + 1;
    }
    let head = remove_chain(input, next_node.as_mut_ptr(), if node_count == 0 { node_count } else { 0 }, node_count, target);
    let mut survivor_count = 0;
    let mut node = head;
    while node != node_count { survivor_count += 1; node = next_node[node]; }
    let output_bytes = survivor_count * 4;
    if output_capacity < output_bytes || (output_bytes != 0 && output.is_null()) { return -2; }
    let mut written = 0;
    node = head;
    while node != node_count {
        let bits = *input.add(node + 1) as i32 as u32;
        for byte in 0..4 { *output.add(written * 4 + byte) = (bits >> (byte * 8)) as u8; }
        written += 1;
        node = next_node[node];
    }
    written as i64
}

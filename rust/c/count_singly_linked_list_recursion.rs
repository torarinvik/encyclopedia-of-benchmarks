fn count_recursive(nodes: &[i64]) -> i64 {
    if nodes.is_empty() {
        return 0;
    }
    if nodes[0] < i32::MIN as i64 || nodes[0] > i32::MAX as i64 {
        return -1;
    }
    let tail_count = count_recursive(&nodes[1..]);
    if tail_count < 0 { return -1; }
    1 + tail_count
}

/// Recursively count a finite singly linked chain represented in node order.
#[no_mangle]
pub extern "C" fn count_singly_linked_list_recursion(input: *const i64, length: usize) -> i64 {
    const MAX_NODES: usize = 64;
    if input.is_null() || length < 1 {
        return -1;
    }
    let count_value = unsafe { *input };
    if !(0..=MAX_NODES as i64).contains(&count_value) {
        return -1;
    }
    let count = count_value as usize;
    if length != count + 1 {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    count_recursive(&input[1..])
}

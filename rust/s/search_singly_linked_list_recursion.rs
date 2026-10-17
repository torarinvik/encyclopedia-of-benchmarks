use std::slice;

const MAX_NODES: usize = 64;
struct Node { value: i32, next: Option<usize> }

fn search_recursion(nodes: &[Node], current: Option<usize>, key: i32) -> bool {
    match current {
        None => false,
        Some(index) => nodes[index].value == key || search_recursion(nodes, nodes[index].next, key),
    }
}

#[no_mangle]
pub unsafe extern "C" fn search_singly_linked_list_recursion(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_NODES + 2 { return -1; }
    let values = slice::from_raw_parts(input, length);
    let count_value = values[0];
    let key_value = values[1];
    if !(0..=MAX_NODES as i64).contains(&count_value) || length != count_value as usize + 2 ||
        key_value < i32::MIN as i64 || key_value > i32::MAX as i64 { return -1; }
    let count = count_value as usize;
    let mut nodes = Vec::with_capacity(count);
    for index in 0..count {
        let value = values[index + 2];
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        nodes.push(Node { value: value as i32, next: if index + 1 < count { Some(index + 1) } else { None } });
    }
    if search_recursion(&nodes, if count == 0 { None } else { Some(0) }, key_value as i32) { 1 } else { 0 }
}

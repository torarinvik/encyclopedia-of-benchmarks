/// Remove a node by one-based distance from the tail in an index-based list.
const MAX_LIST_LENGTH: usize = 1024;
const NONE: usize = MAX_LIST_LENGTH;

#[no_mangle]
pub extern "C" fn remove_nth_node_from_end_of_list(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_LIST_LENGTH + 1 {
        return -1;
    }
    let list_length = length - 1;
    for index in 0..list_length {
        let value = unsafe { *input.add(index + 1) };
        if value < i32::MIN as i64 || value > i32::MAX as i64 {
            return -1;
        }
    }
    let position = unsafe { *input };
    if position < 1 || position as u64 > list_length as u64 {
        return -1;
    }

    let mut next_node = [NONE; MAX_LIST_LENGTH];
    for index in 0..list_length {
        next_node[index] = if index + 1 < list_length { index + 1 } else { NONE };
    }
    let mut node = 0;
    let mut counted = 0;
    while node != NONE {
        node = next_node[node];
        counted += 1;
    }
    if counted != list_length {
        return -1;
    }

    let steps_to_target = counted - position as usize;
    let mut before = NONE;
    node = 0;
    for _ in 0..steps_to_target {
        before = node;
        node = next_node[node];
    }
    let head = if before == NONE { next_node[node] } else { 0 };
    if before != NONE {
        next_node[before] = next_node[node];
    }

    let output_count = counted - 1;
    let output_bytes = output_count * 4;
    if output_capacity < output_bytes || (output_bytes != 0 && output.is_null()) {
        return -2;
    }
    node = head;
    let mut written = 0;
    while node != NONE {
        let bits = unsafe { *input.add(node + 1) as i32 as u32 };
        for byte in 0..4 {
            unsafe {
                *output.add(written * 4 + byte) = (bits >> (byte * 8)) as u8;
            }
        }
        node = next_node[node];
        written += 1;
    }
    if written != output_count {
        return -1;
    }
    written as i64
}

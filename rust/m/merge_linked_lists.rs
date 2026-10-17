const MAX_LIST_LENGTH: usize = 32;
const MAX_TOTAL_NODES: usize = 2 * MAX_LIST_LENGTH;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 2 + MAX_TOTAL_NODES + 1;

#[derive(Clone, Copy)]
struct Node {
    value: i32,
    next: i32,
}

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn merge_linked_lists(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let raw_first = input[0];
    let raw_second = input[1];
    if raw_first < 0 || raw_first > MAX_LIST_LENGTH as i64 ||
        raw_second < 0 || raw_second > MAX_LIST_LENGTH as i64 { return -1; }
    let first_length = raw_first as usize;
    let second_length = raw_second as usize;
    let total = first_length + second_length;
    if total > MAX_TOTAL_NODES || length != 2 + total { return -1; }

    let mut nodes = [Node { value: 0, next: -1 }; MAX_TOTAL_NODES];
    for index in 0..first_length {
        let value = input[2 + index];
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        nodes[index].value = value as i32;
        nodes[index].next = if index + 1 < first_length { (index + 1) as i32 } else { -1 };
    }
    let second_start = first_length;
    for index in 0..second_length {
        let value = input[2 + first_length + index];
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        let node = second_start + index;
        nodes[node].value = value as i32;
        nodes[node].next = if index + 1 < second_length { (node + 1) as i32 } else { -1 };
    }

    let head1 = if first_length == 0 { -1 } else { 0 };
    let head2 = if second_length == 0 { -1 } else { second_start as i32 };
    let mut temp1 = head1;
    let mut temp2 = head2;
    let mut holder2 = -1;
    while temp1 != -1 && temp2 != -1 {
        let holder1 = nodes[temp1 as usize].next;
        nodes[temp1 as usize].next = temp2;
        if holder1 != -1 {
            holder2 = nodes[temp2 as usize].next;
            nodes[temp2 as usize].next = holder1;
        }
        temp1 = holder1;
        temp2 = holder2;
    }

    let mut output_count = 0usize;
    let mut node = head1;
    while node != -1 {
        if node < 0 || node as usize >= total || output_count >= total { return -1; }
        output_count += 1;
        node = nodes[node as usize].next;
    }
    let required = output_count * 8;
    if output.is_null() || output_capacity < required { return -2; }

    node = head1;
    for index in 0..output_count {
        store_i64_le(output, 8 * index, nodes[node as usize].value as i64);
        node = nodes[node as usize].next;
    }
    required as i64
}

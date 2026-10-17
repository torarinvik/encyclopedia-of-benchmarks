const MAX_ITEMS: usize = 128;

fn merge_nodes(values: &[i32; MAX_ITEMS], next: &mut [i32; MAX_ITEMS], left: i32, right: i32) -> i32 {
    if left < 0 { return right; }
    if right < 0 { return left; }
    let left_index = left as usize;
    let right_index = right as usize;
    if values[left_index] <= values[right_index] {
        let following = next[left_index];
        let merged = merge_nodes(values, next, following, right);
        next[left_index] = merged;
        left
    } else {
        let following = next[right_index];
        let merged = merge_nodes(values, next, left, following);
        next[right_index] = merged;
        right
    }
}

fn merge_sort_nodes(values: &[i32; MAX_ITEMS], next: &mut [i32; MAX_ITEMS], head: i32) -> i32 {
    if head < 0 || next[head as usize] < 0 { return head; }
    let mut slow = head;
    let mut fast = next[head as usize];
    while fast >= 0 && next[fast as usize] >= 0 {
        slow = next[slow as usize];
        fast = next[next[fast as usize] as usize];
    }
    let right_head = next[slow as usize];
    next[slow as usize] = -1;
    let left = merge_sort_nodes(values, next, head);
    let right = merge_sort_nodes(values, next, right_head);
    merge_nodes(values, next, left, right)
}

#[no_mangle]
pub unsafe extern "C" fn merge_sort_linked_list(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > 1 + MAX_ITEMS { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    let count_value = input[0];
    if count_value < 0 || count_value > MAX_ITEMS as i64 { return -1; }
    let count = count_value as usize;
    if length != 1 + count { return -1; }
    let mut values = [0i32; MAX_ITEMS];
    let mut next = [-1i32; MAX_ITEMS];
    for i in 0..count {
        if input[1 + i] < i32::MIN as i64 || input[1 + i] > i32::MAX as i64 { return -1; }
        values[i] = input[1 + i] as i32;
        if values[..i].contains(&values[i]) { return -1; }
        next[i] = if i + 1 < count { (i + 1) as i32 } else { -1 };
    }
    let head = merge_sort_nodes(&values, &mut next, if count == 0 { -1 } else { 0 });
    let required = 4 * count;
    if output.is_null() || output_capacity < required { return -2; }
    let mut node = head;
    for i in 0..count {
        let bytes = values[node as usize].to_le_bytes();
        for byte in 0..4 { *output.add(4 * i + byte) = bytes[byte]; }
        node = next[node as usize];
    }
    required as i64
}

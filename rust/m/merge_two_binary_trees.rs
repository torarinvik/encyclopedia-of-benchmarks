/// Merge two heap-indexed trees and encode the result as little-endian i32 slots.
const MAX_TREE_SLOTS: usize = 255;
const MAX_INPUT_LENGTH: usize = 512;
const NULL_SLOT: i64 = -1_000_001;

unsafe fn valid_tree(input: *const i64, start: usize, count: usize) -> bool {
    for index in 0..count {
        let value = *input.add(start + index);
        if value != NULL_SLOT && !(-100_000..=100_000).contains(&value) { return false; }
        if index > 0 && *input.add(start + (index - 1) / 2) == NULL_SLOT && value != NULL_SLOT { return false; }
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn merge_two_binary_trees(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if length < 2 || length > MAX_INPUT_LENGTH || input.is_null() { return -1; }
    let first_count_value = *input;
    if !(0..=MAX_TREE_SLOTS as i64).contains(&first_count_value) { return -1; }
    let first_count = first_count_value as usize;
    let second_count_position = first_count + 1;
    if second_count_position >= length { return -1; }
    let second_count_value = *input.add(second_count_position);
    if !(0..=MAX_TREE_SLOTS as i64).contains(&second_count_value) { return -1; }
    let second_count = second_count_value as usize;
    let first_start = 1;
    let second_start = second_count_position + 1;
    if length != second_start + second_count { return -1; }
    if !valid_tree(input, first_start, first_count) || !valid_tree(input, second_start, second_count) { return -1; }

    let maximum_slots = first_count.max(second_count);
    let mut merged = [0i32; MAX_TREE_SLOTS];
    let mut node_count = 0;
    for index in 0..maximum_slots {
        let first = if index < first_count { *input.add(first_start + index) } else { NULL_SLOT };
        let second = if index < second_count { *input.add(second_start + index) } else { NULL_SLOT };
        if first == NULL_SLOT && second == NULL_SLOT {
            merged[index] = NULL_SLOT as i32;
        } else {
            let first_value = if first == NULL_SLOT { 0 } else { first };
            let second_value = if second == NULL_SLOT { 0 } else { second };
            merged[index] = (first_value + second_value) as i32;
            node_count += 1;
        }
    }
    let mut output_slots = maximum_slots;
    while output_slots > 0 && merged[output_slots - 1] == NULL_SLOT as i32 { output_slots -= 1; }
    let output_bytes = output_slots * 4;
    if output_capacity < output_bytes || (output_bytes != 0 && output.is_null()) { return -2; }
    for index in 0..output_slots {
        for (byte, value) in merged[index].to_le_bytes().iter().enumerate() {
            *output.add(index * 4 + byte) = *value;
        }
    }
    node_count
}

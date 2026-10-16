/// Recursively flatten sorted child chains by merging from the right.
const MAX_LISTS: usize = 8;
const MAX_CHAIN_LENGTH: usize = 8;
const MAX_TOTAL_VALUES: usize = MAX_LISTS * MAX_CHAIN_LENGTH;
const MAX_INPUT_LENGTH: usize = 1 + MAX_LISTS * (1 + MAX_CHAIN_LENGTH);

fn merge_recursive(left: &[i64], right: &[i64], output: &mut [i64],
                   left_index: usize, right_index: usize, output_index: usize) -> usize {
    if left_index == left.len() {
        let remaining = right.len() - right_index;
        output[output_index..output_index + remaining].copy_from_slice(&right[right_index..]);
        return output_index + remaining;
    }
    if right_index == right.len() {
        let remaining = left.len() - left_index;
        output[output_index..output_index + remaining].copy_from_slice(&left[left_index..]);
        return output_index + remaining;
    }
    if left[left_index] < right[right_index] {
        output[output_index] = left[left_index];
        merge_recursive(left, right, output, left_index + 1, right_index, output_index + 1)
    } else {
        output[output_index] = right[right_index];
        merge_recursive(left, right, output, left_index, right_index + 1, output_index + 1)
    }
}

fn flatten_suffix(
    lists: &[[i64; MAX_CHAIN_LENGTH]; MAX_LISTS],
    lengths: &[usize; MAX_LISTS],
    count: usize,
    index: usize,
    output: &mut [i64; MAX_TOTAL_VALUES],
) -> usize {
    if index + 1 == count {
        output[..lengths[index]].copy_from_slice(&lists[index][..lengths[index]]);
        return lengths[index];
    }
    let mut suffix = [0i64; MAX_TOTAL_VALUES];
    let suffix_length = flatten_suffix(lists, lengths, count, index + 1, &mut suffix);
    merge_recursive(&lists[index][..lengths[index]], &suffix[..suffix_length], output, 0, 0, 0)
}

fn store_i64(output: &mut [u8], offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { output[offset + byte] = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub extern "C" fn flatten_multilevel_linked_list(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input[0] < 0 || input[0] > MAX_LISTS as i64 { return -1; }
    let count = input[0] as usize;
    if count == 0 { return if length == 1 { 0 } else { -1 }; }

    let mut lists = [[0i64; MAX_CHAIN_LENGTH]; MAX_LISTS];
    let mut lengths = [0usize; MAX_LISTS];
    let mut total = 0usize;
    let mut cursor = 1usize;
    for list in 0..count {
        if cursor >= length || input[cursor] < 1 || input[cursor] > MAX_CHAIN_LENGTH as i64 { return -1; }
        let chain_length = input[cursor] as usize;
        cursor += 1;
        if chain_length > length - cursor { return -1; }
        lengths[list] = chain_length;
        for item in 0..chain_length {
            let value = input[cursor];
            cursor += 1;
            if !(-1000..=1000).contains(&value) ||
                (item > 0 && value < lists[list][item - 1]) { return -1; }
            lists[list][item] = value;
        }
        total += chain_length;
    }
    if cursor != length { return -1; }
    let required = total * 8;
    if output.is_null() || capacity < required { return -2; }

    let mut flattened = [0i64; MAX_TOTAL_VALUES];
    flatten_suffix(&lists, &lengths, count, 0, &mut flattened);
    let output = unsafe { std::slice::from_raw_parts_mut(output, required) };
    for i in 0..total { store_i64(output, 8 * i, flattened[i]); }
    total as i64
}

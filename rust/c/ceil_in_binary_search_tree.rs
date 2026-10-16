const MAX_NODE_COUNT: usize = 127;
const MAX_INPUT_LENGTH: usize = 3 + 3 * MAX_NODE_COUNT;
const VALUE_MIN: i64 = -1_000_000;
const VALUE_MAX: i64 = 1_000_000;
const INVALID_RESULT: i64 = i64::MIN + 1;
const NO_CEIL_RESULT: i64 = i64::MIN;

/// Return the least tree value greater than or equal to the query.
#[no_mangle]
pub unsafe extern "C" fn ceil_in_binary_search_tree(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let node_count_value = values[0];
    let root_index_value = values[1];
    let key = values[2];
    if !(0..=MAX_NODE_COUNT as i64).contains(&node_count_value) || !(VALUE_MIN..=VALUE_MAX).contains(&key) {
        return INVALID_RESULT;
    }
    let node_count = node_count_value as usize;
    if length != 3 + 3 * node_count { return INVALID_RESULT; }
    if node_count == 0 { return if root_index_value == -1 { NO_CEIL_RESULT } else { INVALID_RESULT }; }
    if root_index_value < 0 || root_index_value >= node_count_value { return INVALID_RESULT; }

    let mut current = root_index_value as usize;
    let mut best = NO_CEIL_RESULT;
    let mut steps = 0;
    while current < node_count {
        if steps >= node_count { return INVALID_RESULT; }
        let offset = 3 + 3 * current;
        let value = values[offset];
        let left = values[offset + 1];
        let right = values[offset + 2];
        if !(VALUE_MIN..=VALUE_MAX).contains(&value) || left < -1 || right < -1 ||
            left >= node_count_value || right >= node_count_value { return INVALID_RESULT; }
        if value == key { return value; }
        if value < key {
            current = if right == -1 { node_count } else { right as usize };
        } else {
            best = value;
            current = if left == -1 { node_count } else { left as usize };
        }
        steps += 1;
    }
    best
}

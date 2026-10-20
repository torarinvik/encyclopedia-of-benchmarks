// Adapted from cp-algorithms Sqrt Tree; CC BY-SA 4.0, see package LICENSE.txt.
const MAX_ITEMS: usize = 256;
const MAX_QUERIES: usize = 256;
const MAX_LEVELS: usize = 16;
const MAX_NODES: usize = 512;
const MAX_BETWEEN: usize = 512;
const MAX_INPUT_VALUES: usize = 770;
const VALUE_LIMIT: i64 = 1_000_000_000;

struct State {
    values: [i64; MAX_ITEMS],
    prefix: [i64; MAX_LEVELS * MAX_ITEMS],
    suffix: [i64; MAX_LEVELS * MAX_ITEMS],
    between: [i64; MAX_LEVELS * MAX_BETWEEN],
    used_values: [usize; MAX_LEVELS],
    used_between: [usize; MAX_LEVELS],
    left: [usize; MAX_NODES],
    right: [usize; MAX_NODES],
    depth: [usize; MAX_NODES],
    value_offset: [usize; MAX_NODES],
    between_offset: [usize; MAX_NODES],
    block_size: [usize; MAX_NODES],
    block_count: [usize; MAX_NODES],
    child_start: [usize; MAX_NODES],
    children: [usize; MAX_NODES],
    node_count: usize,
    child_count: usize,
}

fn create_node(state: &mut State, left: usize, right: usize, depth: usize) -> usize {
    let node = state.node_count;
    state.node_count += 1;
    state.left[node] = left;
    state.right[node] = right;
    state.depth[node] = depth;
    node
}

fn build_node(state: &mut State, node: usize) {
    let left = state.left[node];
    let right = state.right[node];
    let node_length = right - left;
    let depth = state.depth[node];
    if node_length <= 2 { return; }
    let mut block_size = 1;
    while block_size * block_size < node_length { block_size += 1; }
    let block_count = (node_length + block_size - 1) / block_size;
    let value_offset = state.used_values[depth];
    let between_offset = state.used_between[depth];
    state.value_offset[node] = value_offset;
    state.between_offset[node] = between_offset;
    state.block_size[node] = block_size;
    state.block_count[node] = block_count;
    state.used_values[depth] += node_length;
    state.used_between[depth] += block_count * block_count;

    let mut block_min = [0i64; MAX_ITEMS];
    for block in 0..block_count {
        let start = left + block * block_size;
        let end = (start + block_size).min(right);
        let first = value_offset + start - left;
        state.prefix[depth * MAX_ITEMS + first] = state.values[start];
        for index in start + 1..end {
            let slot = value_offset + index - left;
            state.prefix[depth * MAX_ITEMS + slot] =
                state.prefix[depth * MAX_ITEMS + slot - 1].min(state.values[index]);
        }
        let last = value_offset + end - 1 - left;
        state.suffix[depth * MAX_ITEMS + last] = state.values[end - 1];
        for index in (start + 1..end).rev() {
            let slot = value_offset + index - 1 - left;
            state.suffix[depth * MAX_ITEMS + slot] =
                state.values[index - 1].min(state.suffix[depth * MAX_ITEMS + slot + 1]);
        }
        block_min[block] = state.prefix[depth * MAX_ITEMS + last];
    }
    for first in 0..block_count {
        let mut aggregate = block_min[first];
        for last in first..block_count {
            if last != first { aggregate = aggregate.min(block_min[last]); }
            state.between[depth * MAX_BETWEEN + between_offset + first * block_count + last] = aggregate;
        }
    }

    let child_start = state.child_count;
    state.child_start[node] = child_start;
    for block in 0..block_count {
        let start = left + block * block_size;
        let end = (start + block_size).min(right);
        let child = create_node(state, start, end, depth + 1);
        state.children[state.child_count] = child;
        state.child_count += 1;
    }
    for block in 0..block_count { build_node(state, state.children[child_start + block]); }
}

fn query_node(state: &State, node: usize, left: usize, right: usize) -> i64 {
    let node_left = state.left[node];
    let node_right = state.right[node];
    if node_right - node_left <= 2 {
        let mut answer = state.values[left];
        for index in left + 1..=right { answer = answer.min(state.values[index]); }
        return answer;
    }
    let block_size = state.block_size[node];
    let left_block = (left - node_left) / block_size;
    let right_block = (right - node_left) / block_size;
    if left_block == right_block {
        return query_node(state, state.children[state.child_start[node] + left_block], left, right);
    }
    let depth = state.depth[node];
    let offset = state.value_offset[node];
    let mut answer = state.suffix[depth * MAX_ITEMS + offset + left - node_left];
    if left_block + 1 < right_block {
        let count = state.block_count[node];
        let middle = state.between_offset[node] + (left_block + 1) * count + right_block - 1;
        answer = answer.min(state.between[depth * MAX_BETWEEN + middle]);
    }
    answer.min(state.prefix[depth * MAX_ITEMS + offset + right - node_left])
}

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; } }
}

#[no_mangle]
pub unsafe extern "C" fn sqrt_tree(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_VALUES { return -1; }
    let item_count_value = *input;
    let query_count_value = *input.add(1);
    if !(1..=MAX_ITEMS as i64).contains(&item_count_value)
        || !(0..=MAX_QUERIES as i64).contains(&query_count_value) { return -1; }
    let item_count = item_count_value as usize;
    let query_count = query_count_value as usize;
    if length != 2 + item_count + 2 * query_count { return -1; }
    for index in 0..item_count {
        let value = *input.add(2 + index);
        if !(-VALUE_LIMIT..=VALUE_LIMIT).contains(&value) { return -1; }
    }
    let query_offset = 2 + item_count;
    for query in 0..query_count {
        let left = *input.add(query_offset + 2 * query);
        let right = *input.add(query_offset + 2 * query + 1);
        if left < 0 || right < left || right >= item_count_value { return -1; }
    }
    let required = 8 * query_count;
    if output_capacity < required || (required != 0 && output.is_null()) { return -2; }

    let mut state = State {
        values: [0; MAX_ITEMS], prefix: [0; MAX_LEVELS * MAX_ITEMS], suffix: [0; MAX_LEVELS * MAX_ITEMS],
        between: [0; MAX_LEVELS * MAX_BETWEEN], used_values: [0; MAX_LEVELS], used_between: [0; MAX_LEVELS],
        left: [0; MAX_NODES], right: [0; MAX_NODES], depth: [0; MAX_NODES],
        value_offset: [0; MAX_NODES], between_offset: [0; MAX_NODES], block_size: [0; MAX_NODES],
        block_count: [0; MAX_NODES], child_start: [0; MAX_NODES], children: [0; MAX_NODES],
        node_count: 0, child_count: 0,
    };
    for index in 0..item_count { state.values[index] = *input.add(index + 2); }
    let root = create_node(&mut state, 0, item_count, 0);
    build_node(&mut state, root);
    for query in 0..query_count {
        let left = *input.add(query_offset + 2 * query) as usize;
        let right = *input.add(query_offset + 2 * query + 1) as usize;
        store_i64_le(output, 8 * query, query_node(&state, root, left, right));
    }
    required as i64
}

// Adapted from cp-algorithms Sqrt Tree; CC BY-SA 4.0, see package LICENSE.txt.
module sqrt_tree;

const usz MAX_ITEMS = 256;
const usz MAX_QUERIES = 256;
const usz MAX_LEVELS = 16;
const usz MAX_NODES = 2 * MAX_ITEMS;
const usz MAX_BETWEEN = 2 * MAX_ITEMS;
const usz MAX_INPUT_VALUES = 2 + MAX_ITEMS + 2 * MAX_QUERIES;
const long VALUE_LIMIT = 1000000000;

struct SqrtTreeState {
    long* values;
    long[MAX_LEVELS * MAX_ITEMS] prefix;
    long[MAX_LEVELS * MAX_ITEMS] suffix;
    long[MAX_LEVELS * MAX_BETWEEN] between;
    usz[MAX_LEVELS] used_values;
    usz[MAX_LEVELS] used_between;
    usz[MAX_NODES] left;
    usz[MAX_NODES] right;
    usz[MAX_NODES] depth;
    usz[MAX_NODES] value_offset;
    usz[MAX_NODES] between_offset;
    usz[MAX_NODES] block_size;
    usz[MAX_NODES] block_count;
    usz[MAX_NODES] child_start;
    usz[MAX_NODES] children;
    usz node_count;
    usz child_count;
}

fn long min_i64(long a, long b) { return a < b ? a : b; }

fn usz create_node(SqrtTreeState* state, usz left, usz right, usz depth) {
    usz node = state.node_count;
    state.node_count++;
    state.left[node] = left;
    state.right[node] = right;
    state.depth[node] = depth;
    return node;
}

fn void build_node(SqrtTreeState* state, usz node) {
    usz left = state.left[node];
    usz right = state.right[node];
    usz length = right - left;
    usz depth = state.depth[node];
    if (length <= 2) return;
    usz block_size = 1;
    while (block_size * block_size < length) block_size++;
    usz block_count = (length + block_size - 1) / block_size;
    usz value_offset = state.used_values[depth];
    usz between_offset = state.used_between[depth];
    state.value_offset[node] = value_offset;
    state.between_offset[node] = between_offset;
    state.block_size[node] = block_size;
    state.block_count[node] = block_count;
    state.used_values[depth] += length;
    state.used_between[depth] += block_count * block_count;

    long[MAX_ITEMS] block_min = {};
    for (usz block = 0; block < block_count; block++) {
        usz start = left + block * block_size;
        usz end = start + block_size;
        if (end > right) end = right;
        usz first = value_offset + start - left;
        state.prefix[depth * MAX_ITEMS + first] = state.values[start];
        for (usz index = start + 1; index < end; index++) {
            usz slot = value_offset + index - left;
            state.prefix[depth * MAX_ITEMS + slot] = min_i64(
                state.prefix[depth * MAX_ITEMS + slot - 1], state.values[index]);
        }
        usz last = value_offset + end - 1 - left;
        state.suffix[depth * MAX_ITEMS + last] = state.values[end - 1];
        for (usz index = end - 1; index > start; index--) {
            usz slot = value_offset + index - 1 - left;
            state.suffix[depth * MAX_ITEMS + slot] = min_i64(
                state.values[index - 1], state.suffix[depth * MAX_ITEMS + slot + 1]);
        }
        block_min[block] = state.prefix[depth * MAX_ITEMS + last];
    }
    for (usz first = 0; first < block_count; first++) {
        long aggregate = block_min[first];
        for (usz last = first; last < block_count; last++) {
            if (last != first) aggregate = min_i64(aggregate, block_min[last]);
            state.between[depth * MAX_BETWEEN + between_offset + first * block_count + last] = aggregate;
        }
    }

    usz child_start = state.child_count;
    state.child_start[node] = child_start;
    for (usz block = 0; block < block_count; block++) {
        usz start = left + block * block_size;
        usz end = start + block_size;
        if (end > right) end = right;
        usz child = create_node(state, start, end, depth + 1);
        state.children[state.child_count] = child;
        state.child_count++;
    }
    for (usz block = 0; block < block_count; block++) build_node(state, state.children[child_start + block]);
}

fn long query_node(SqrtTreeState* state, usz node, usz left, usz right) {
    usz node_left = state.left[node];
    usz node_right = state.right[node];
    if (node_right - node_left <= 2) {
        long answer = state.values[left];
        for (usz index = left + 1; index <= right; index++) answer = min_i64(answer, state.values[index]);
        return answer;
    }
    usz block_size = state.block_size[node];
    usz left_block = (left - node_left) / block_size;
    usz right_block = (right - node_left) / block_size;
    if (left_block == right_block)
        return query_node(state, state.children[state.child_start[node] + left_block], left, right);
    usz depth = state.depth[node];
    usz offset = state.value_offset[node];
    long answer = state.suffix[depth * MAX_ITEMS + offset + left - node_left];
    if (left_block + 1 < right_block) {
        usz count = state.block_count[node];
        usz middle = state.between_offset[node] + (left_block + 1) * count + right_block - 1;
        answer = min_i64(answer, state.between[depth * MAX_BETWEEN + middle]);
    }
    answer = min_i64(answer, state.prefix[depth * MAX_ITEMS + offset + right - node_left]);
    return answer;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255ul);
        bits >>= 8;
    }
}

fn long sqrt_tree(long* input, usz length, char* output, usz output_capacity)
    @export("sqrt_tree") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    long item_count_value = input[0];
    long query_count_value = input[1];
    if (item_count_value < 1 || item_count_value > (long)MAX_ITEMS ||
        query_count_value < 0 || query_count_value > (long)MAX_QUERIES) return -1;
    usz item_count = (usz)item_count_value;
    usz query_count = (usz)query_count_value;
    if (length != 2 + item_count + 2 * query_count) return -1;
    for (usz index = 0; index < item_count; index++) {
        long value = input[2 + index];
        if (value < -VALUE_LIMIT || value > VALUE_LIMIT) return -1;
    }
    usz query_offset = 2 + item_count;
    for (usz query = 0; query < query_count; query++) {
        long left = input[query_offset + 2 * query];
        long right = input[query_offset + 2 * query + 1];
        if (left < 0 || right < left || right >= item_count_value) return -1;
    }
    usz required = 8 * query_count;
    if (output_capacity < required || (required != 0 && output == null)) return -2;

    SqrtTreeState state = {};
    state.values = input + 2;
    usz root = create_node(&state, 0, item_count, 0);
    build_node(&state, root);
    for (usz query = 0; query < query_count; query++) {
        usz left = (usz)input[query_offset + 2 * query];
        usz right = (usz)input[query_offset + 2 * query + 1];
        store_i64_le(output, 8 * query, query_node(&state, root, left, right));
    }
    return (long)required;
}

const MAX_NODE_COUNT: usize = 127;
const MAX_INPUT_LENGTH: usize = 3 + 3 * MAX_NODE_COUNT;
const VALUE_MIN: i64 = -1_000_000;
const VALUE_MAX: i64 = 1_000_000;
const INVALID_RESULT: i64 = -9223372036854775807;
const NO_CEIL_RESULT: i64 = -9223372036854775807 - 1;

export fn ceil_in_binary_search_tree(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const node_count_value = input[0];
    const root_index_value = input[1];
    const key = input[2];
    if (node_count_value < 0 or node_count_value > MAX_NODE_COUNT or key < VALUE_MIN or key > VALUE_MAX) return INVALID_RESULT;
    const node_count: usize = @intCast(node_count_value);
    if (length != 3 + 3 * node_count) return INVALID_RESULT;
    if (node_count == 0) return if (root_index_value == -1) NO_CEIL_RESULT else INVALID_RESULT;
    if (root_index_value < 0 or root_index_value >= node_count_value) return INVALID_RESULT;

    var current: usize = @intCast(root_index_value);
    var best: i64 = NO_CEIL_RESULT;
    var steps: usize = 0;
    while (current < node_count) {
        if (steps >= node_count) return INVALID_RESULT;
        const offset = 3 + 3 * current;
        const value = input[offset];
        const left = input[offset + 1];
        const right = input[offset + 2];
        if (value < VALUE_MIN or value > VALUE_MAX or left < -1 or right < -1 or
            left >= node_count_value or right >= node_count_value) return INVALID_RESULT;
        if (value == key) return value;
        if (value < key) current = if (right == -1) node_count else @intCast(right)
        else {
            best = value;
            current = if (left == -1) node_count else @intCast(left);
        }
        steps += 1;
    }
    return best;
}

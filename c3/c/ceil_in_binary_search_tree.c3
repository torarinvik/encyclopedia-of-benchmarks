module ceil_in_binary_search_tree;

const usz MAX_NODE_COUNT = 127;
const usz MAX_INPUT_LENGTH = 3 + 3 * MAX_NODE_COUNT;
const long VALUE_MIN = -1000000;
const long VALUE_MAX = 1000000;
const long INVALID_RESULT = -9223372036854775807L;
const long NO_CEIL_RESULT = -9223372036854775807L - 1L;

fn long ceil_in_binary_search_tree(long* input, usz length) @export("ceil_in_binary_search_tree") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long node_count_value = input[0];
    long root_index_value = input[1];
    long key = input[2];
    if (node_count_value < 0 || node_count_value > (long)MAX_NODE_COUNT || key < VALUE_MIN || key > VALUE_MAX) return INVALID_RESULT;
    usz node_count = (usz)node_count_value;
    if (length != 3 + 3 * node_count) return INVALID_RESULT;
    if (node_count == 0) return root_index_value == -1 ? NO_CEIL_RESULT : INVALID_RESULT;
    if (root_index_value < 0 || root_index_value >= node_count_value) return INVALID_RESULT;

    usz current = (usz)root_index_value;
    long best = NO_CEIL_RESULT;
    for (usz steps = 0; current != (usz)-1; steps++) {
        if (steps >= node_count) return INVALID_RESULT;
        usz offset = 3 + 3 * current;
        long value = input[offset];
        long left = input[offset + 1];
        long right = input[offset + 2];
        if (value < VALUE_MIN || value > VALUE_MAX || left < -1 || right < -1 ||
            left >= node_count_value || right >= node_count_value) return INVALID_RESULT;
        if (value == key) return value;
        if (value < key) {
            current = right == -1 ? (usz)-1 : (usz)right;
        } else {
            best = value;
            current = left == -1 ? (usz)-1 : (usz)left;
        }
    }
    return best;
}

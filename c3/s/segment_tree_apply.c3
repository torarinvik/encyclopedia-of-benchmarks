module segment_tree_apply;

const usz MAX_LENGTH = 64;
const usz MAX_OPERATIONS = 20;
const usz MAX_PARSEABLE_INPUT_VALUES = 147;
const usz MAX_TREE_SIZE = 128;
const long MIN_INITIAL_VALUE = -1;
const long MAX_INITIAL_VALUE = 1;
const long MIN_MULTIPLIER = -2;
const long MAX_MULTIPLIER = 2;
const long CHECKSUM_OFFSET = 67_108_865;

fn usz padded_size(usz length) {
    usz result = 1;
    while (result < length) result <<= 1;
    return result;
}

fn void apply_range(int* tree, int* operand, int left, int right, int multiplier,
                    int segment_left, int segment_right, int node) {
    if (left <= segment_left && segment_right <= right) {
        operand[node] *= multiplier;
        tree[node] *= multiplier;
        return;
    }
    if (right < segment_left || segment_right < left) return;
    int middle = (segment_left + segment_right) / 2;
    apply_range(tree, operand, left, right, multiplier, segment_left, middle, 2 * node);
    apply_range(tree, operand, left, right, multiplier, middle + 1, segment_right, 2 * node + 1);
    tree[node] = operand[node] * (tree[2 * node] + tree[2 * node + 1]);
}

fn int query_range(int* tree, int* operand, int left, int right,
                   int segment_left, int segment_right, int node) {
    if (left <= segment_left && segment_right <= right) return tree[node];
    if (right < segment_left || segment_right < left) return 0;
    int middle = (segment_left + segment_right) / 2;
    int child_sum = query_range(tree, operand, left, right, segment_left, middle, 2 * node) +
                    query_range(tree, operand, left, right, middle + 1, segment_right, 2 * node + 1);
    return operand[node] * child_sum;
}

fn long segment_tree_apply_benchmark(long* input, usz length) @export("segment_tree_apply_benchmark") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_LENGTH) return -1;
    usz array_length = (usz)input[0];
    if (length < array_length + 2) return -1;
    for (usz index = 0; index < array_length; index++)
        if (input[index + 1] < MIN_INITIAL_VALUE || input[index + 1] > MAX_INITIAL_VALUE) return -1;
    long operation_count_value = input[array_length + 1];
    if (operation_count_value < 0 || operation_count_value > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)operation_count_value;
    usz cursor = array_length + 2;
    if (cursor + 4 * operation_count != length) return -1;

    usz base = padded_size(array_length);
    int[MAX_TREE_SIZE] tree = zeroed;
    int[MAX_TREE_SIZE] operand;
    for (usz node = 0; node < MAX_TREE_SIZE; node++) operand[node] = 1;
    for (usz index = 0; index < array_length; index++) tree[base + index] = (int)input[index + 1];
    for (usz node = base - 1; node > 0; node--) tree[node] = tree[2 * node] + tree[2 * node + 1];

    long checksum = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        long opcode = input[cursor++];
        long left_value = input[cursor++];
        long right_value = input[cursor++];
        long argument = input[cursor++];
        if (left_value < 0 || left_value > right_value || right_value >= (long)array_length) return -1;
        if (opcode == 0) {
            if (argument < MIN_MULTIPLIER || argument > MAX_MULTIPLIER) return -1;
            apply_range(&tree[0], &operand[0], (int)left_value + 1, (int)right_value + 1,
                        (int)argument, 1, (int)base, 1);
        } else if (opcode == 1) {
            if (argument != 0) return -1;
            int result = query_range(&tree[0], &operand[0], (int)left_value + 1,
                (int)right_value + 1, 1, (int)base, 1);
            checksum += (long)(operation + 1) * ((long)result + CHECKSUM_OFFSET);
        } else {
            return -1;
        }
    }
    return checksum;
}

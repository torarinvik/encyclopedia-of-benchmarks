module segment_tree2_d;

const usz MAX_DIMENSION = 16;
const usz MAX_OPERATIONS = 256;
const usz MAX_PARSEABLE_INPUT_VALUES = 1284;
const usz MAX_TREE_NODES = 32;
const long MIN_CELL_VALUE = -1_000;
const long MAX_CELL_VALUE = 1_000;
const long CHECKSUM_OFFSET = 256_001;

fn usz padded_size(usz size) {
    usz result = 1;
    while (result < size) result <<= 1;
    return result;
}

fn void update_columns(int* tree, usz row_node, usz column_base, usz column, int value) {
    usz node = column_base + column;
    tree[row_node * MAX_TREE_NODES + node] = value;
    while (node > 1) {
        node >>= 1;
        tree[row_node * MAX_TREE_NODES + node] =
            tree[row_node * MAX_TREE_NODES + 2 * node] +
            tree[row_node * MAX_TREE_NODES + 2 * node + 1];
    }
}

fn long query_columns(int* tree, usz row_node, usz column_base, usz left_arg, usz right_arg) {
    usz left = left_arg + column_base;
    usz right = right_arg + column_base;
    long sum = 0;
    while (left < right) {
        if ((left & 1) != 0) sum += tree[row_node * MAX_TREE_NODES + left++];
        if ((right & 1) != 0) sum += tree[row_node * MAX_TREE_NODES + --right];
        left >>= 1;
        right >>= 1;
    }
    return sum;
}

fn void update_point(int* tree, usz row_base, usz column_base,
                     usz row, usz column, int value) {
    usz row_node = row_base + row;
    update_columns(tree, row_node, column_base, column, value);
    while (row_node > 1) {
        row_node >>= 1;
        int child_value =
            tree[(2 * row_node) * MAX_TREE_NODES + column_base + column] +
            tree[(2 * row_node + 1) * MAX_TREE_NODES + column_base + column];
        update_columns(tree, row_node, column_base, column, child_value);
    }
}

fn long query_rectangle(int* tree, usz row_base, usz column_base,
                        usz top, usz bottom, usz left, usz right) {
    usz row_left = top + row_base;
    usz row_right = bottom + row_base;
    long sum = 0;
    while (row_left < row_right) {
        if ((row_left & 1) != 0)
            sum += query_columns(tree, row_left++, column_base, left, right);
        if ((row_right & 1) != 0)
            sum += query_columns(tree, --row_right, column_base, left, right);
        row_left >>= 1;
        row_right >>= 1;
    }
    return sum;
}

fn long segment_tree2_d_benchmark(long* input, usz length) @export("segment_tree2_d_benchmark") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_DIMENSION ||
        input[1] < 1 || input[1] > (long)MAX_DIMENSION) return -1;
    usz rows = (usz)input[0];
    usz columns = (usz)input[1];
    if (input[2] < 0 || input[2] > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)input[2];
    if (3 + 5 * operation_count != length) return -1;

    usz row_base = padded_size(rows);
    usz column_base = padded_size(columns);
    int[MAX_TREE_NODES * MAX_TREE_NODES] tree = zeroed;
    usz cursor = 3;
    long checksum = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        long opcode = input[cursor++];
        long first = input[cursor++];
        long second = input[cursor++];
        long third = input[cursor++];
        long fourth = input[cursor++];
        if (opcode == 0) {
            if (first < 0 || first >= (long)rows || second < 0 || second >= (long)columns ||
                third < MIN_CELL_VALUE || third > MAX_CELL_VALUE || fourth != 0) return -1;
            update_point(&tree[0], row_base, column_base, (usz)first, (usz)second, (int)third);
        } else if (opcode == 1) {
            if (first < 0 || first > second || second > (long)rows ||
                third < 0 || third > fourth || fourth > (long)columns) return -1;
            long result = query_rectangle(&tree[0], row_base, column_base,
                (usz)first, (usz)second, (usz)third, (usz)fourth);
            checksum += (long)(operation + 1) * (result + CHECKSUM_OFFSET);
        } else {
            return -1;
        }
    }
    return checksum;
}

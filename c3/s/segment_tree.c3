module segment_tree;

const usz MAX_ITEMS = 256;
const usz MAX_OPERATIONS = 512;
const usz MAX_INPUT_VALUES = MAX_ITEMS + 3 + 3 * MAX_OPERATIONS;
const long VALUE_LIMIT = 1000000;
const long QUERY_OFFSET = 256000001;
const long FINAL_OFFSET = 1000001;

fn long identity(long mode) {
    if (mode == 1) return VALUE_LIMIT + 1;
    if (mode == 2) return -(VALUE_LIMIT + 1);
    return 0;
}

fn long combine(long mode, long left, long right) {
    if (mode == 1) return left < right ? left : right;
    if (mode == 2) return left > right ? left : right;
    return left + right;
}

fn long segment_tree_benchmark(long* values, usz length) @export("segment_tree_benchmark") {
    if (length < 3 || length > MAX_INPUT_VALUES) return -1;
    long mode = values[0];
    long item_count_value = values[1];
    if (mode < 0 || mode > 2 || item_count_value < 1 || item_count_value > (long)MAX_ITEMS) return -1;
    usz item_count = (usz)item_count_value;
    if (length < item_count + 3) return -1;
    long operation_count_value = values[item_count + 2];
    if (operation_count_value < 0 || operation_count_value > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)operation_count_value;
    if (length != item_count + 3 + 3 * operation_count) return -1;

    long[MAX_ITEMS] data;
    for (usz i = 0; i < item_count; i++) {
        long value = values[i + 2];
        if (value < -VALUE_LIMIT || value > VALUE_LIMIT) return -1;
        data[i] = value;
    }
    for (usz operation = 0; operation < operation_count; operation++) {
        usz position = item_count + 3 + 3 * operation;
        long opcode = values[position];
        long first = values[position + 1];
        long second = values[position + 2];
        if (opcode == 0) {
            if (first < 0 || first >= item_count_value || second < -VALUE_LIMIT || second > VALUE_LIMIT) return -1;
        } else if (opcode == 1) {
            if (first < 0 || second < first || second >= item_count_value) return -1;
        } else {
            return -1;
        }
    }

    usz base = 1;
    while (base < item_count) base *= 2;
    long empty = identity(mode);
    long[2 * MAX_ITEMS] tree;
    for (usz i = 0; i < 2 * base; i++) tree[i] = empty;
    for (usz i = 0; i < item_count; i++) tree[base + i] = data[i];
    for (usz node = base; node > 1;) {
        node--;
        tree[node] = combine(mode, tree[2 * node], tree[2 * node + 1]);
    }

    long checksum = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        usz position = item_count + 3 + 3 * operation;
        long opcode = values[position];
        usz first = (usz)values[position + 1];
        if (opcode == 0) {
            long value = values[position + 2];
            data[first] = value;
            usz node = base + first;
            tree[node] = value;
            while (node > 1) {
                node /= 2;
                tree[node] = combine(mode, tree[2 * node], tree[2 * node + 1]);
            }
        } else {
            usz left = base + first;
            usz right = base + (usz)values[position + 2] + 1;
            long result = empty;
            while (left < right) {
                if (left & 1) result = combine(mode, result, tree[left++]);
                if (right & 1) result = combine(mode, result, tree[--right]);
                left /= 2;
                right /= 2;
            }
            checksum += (long)(operation + 1) * (result + QUERY_OFFSET);
        }
    }
    for (usz i = 0; i < item_count; i++) checksum += (long)(operation_count + i + 1) * (data[i] + FINAL_OFFSET);
    return checksum;
}

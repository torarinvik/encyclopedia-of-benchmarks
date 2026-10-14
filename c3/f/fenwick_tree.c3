module fenwick_tree;

const usz MAX_ITEMS = 256;
const usz MAX_OPERATIONS = 512;
const usz MAX_INPUT_VALUES = 2 + 3 * MAX_OPERATIONS;
const long VALUE_LIMIT = 1000000;
const long QUERY_OFFSET = 131072000001;
const long FINAL_OFFSET = 512000001;

fn usz lowbit(usz index) { return index & (0 - index); }

fn long prefix_sum(long* tree, usz count) {
    long sum = 0;
    while (count > 0) {
        sum += tree[count];
        count -= lowbit(count);
    }
    return sum;
}

fn long fenwick_tree_benchmark(long* values, usz length) @export("fenwick_tree_benchmark") {
    if (length < 2 || length > MAX_INPUT_VALUES) return -1;
    long item_count_value = values[0];
    long operation_count_value = values[1];
    if (item_count_value < 1 || item_count_value > (long)MAX_ITEMS ||
        operation_count_value < 0 || operation_count_value > (long)MAX_OPERATIONS) return -1;
    usz item_count = (usz)item_count_value;
    usz operation_count = (usz)operation_count_value;
    if (length != 2 + 3 * operation_count) return -1;
    for (usz operation = 0; operation < operation_count; operation++) {
        usz position = 2 + 3 * operation;
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

    long[MAX_ITEMS] data;
    long[MAX_ITEMS + 1] tree;
    for (usz i = 0; i < item_count; i++) data[i] = 0;
    for (usz i = 0; i <= item_count; i++) tree[i] = 0;
    long checksum = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        usz position = 2 + 3 * operation;
        long opcode = values[position];
        usz first = (usz)values[position + 1];
        long second = values[position + 2];
        if (opcode == 0) {
            data[first] += second;
            for (usz index = first + 1; index <= item_count; index += lowbit(index)) tree[index] += second;
        } else {
            usz right = (usz)second;
            long result = prefix_sum(&tree[0], right + 1) - prefix_sum(&tree[0], first);
            checksum += (long)(operation + 1) * (result + QUERY_OFFSET);
        }
    }
    for (usz i = 0; i < item_count; i++) checksum += (long)(operation_count + i + 1) * (data[i] + FINAL_OFFSET);
    return checksum;
}

module binary_indexed_tree;

const int MAX_ITEMS = 256, MAX_OPERATIONS = 512;
const usz MAX_INPUT_VALUES = 2 + 3 * MAX_OPERATIONS;
const long VALUE_LIMIT = 1000000, QUERY_OFFSET = 131072000001, FINAL_OFFSET = 512000001;

fn int lowbit(int index) { return index & -index; }
fn int prefix_sum(int* tree, int count) {
    int sum = 0;
    while (count > 0) { sum += tree[count]; count -= lowbit(count); }
    return sum;
}

fn long binary_indexed_tree(long* values, usz length) @export("binary_indexed_tree") {
    if (values == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    long n_value = values[0], op_value = values[1];
    if (n_value < 2 || n_value > MAX_ITEMS || (n_value & (n_value - 1)) != 0 || op_value < 0 || op_value > MAX_OPERATIONS) return -1;
    int n = (int)n_value, operations = (int)op_value;
    if (length != 2 + 3 * (usz)operations) return -1;
    for (int op = 0; op < operations; op++) {
        usz at = 2 + 3 * (usz)op;
        long code = values[at], first = values[at + 1], second = values[at + 2];
        if (code == 0) { if (first < 0 || first >= n_value || second < -VALUE_LIMIT || second > VALUE_LIMIT) return -1; }
        else if (code == 1) { if (first < 0 || second < first || second >= n_value) return -1; }
        else return -1;
    }
    int[MAX_ITEMS] data;
    int[MAX_ITEMS + 2] tree;
    for (int i = 0; i < MAX_ITEMS; i++) data[i] = 0;
    for (int i = 0; i < MAX_ITEMS + 2; i++) tree[i] = 0;
    long checksum = 0;
    for (int op = 0; op < operations; op++) {
        usz at = 2 + 3 * (usz)op;
        int code = (int)values[at], first = (int)values[at + 1], second = (int)values[at + 2];
        if (code == 0) {
            data[first] += second;
            int start = first + 1;
            while (start <= n + 1) { tree[start] += second; start += lowbit(start); }
        } else {
            int result = prefix_sum(&tree[0], second + 1) - prefix_sum(&tree[0], first);
            checksum += (long)(op + 1) * ((long)result + QUERY_OFFSET);
        }
    }
    for (int i = 0; i < n; i++) checksum += (long)(operations + i + 1) * ((long)data[i] + FINAL_OFFSET);
    return checksum;
}

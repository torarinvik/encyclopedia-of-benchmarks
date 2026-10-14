module union_find;

const usz MAX_ITEMS = 256;
const usz MAX_OPERATIONS = 512;
const usz MAX_INPUT_VALUES = 2 + 3 * MAX_OPERATIONS;
const long OBSERVED_OFFSET = 1000003;

fn usz find_root(long* parent, usz item) {
    while ((usz)parent[item] != item) {
        parent[item] = parent[(usz)parent[item]];
        item = (usz)parent[item];
    }
    return item;
}

fn long union_find_benchmark(long* values, usz length) @export("union_find_benchmark") {
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
        if (opcode == 0 || opcode == 1) {
            if (first < 0 || first >= item_count_value || second < 0 || second >= item_count_value) return -1;
        } else if (opcode == 2) {
            if (first != 0 || second != 0) return -1;
        } else {
            return -1;
        }
    }

    long[MAX_ITEMS] parent;
    long[MAX_ITEMS] set_size;
    for (usz i = 0; i < item_count; i++) {
        parent[i] = (long)i;
        set_size[i] = 1;
    }
    usz components = item_count;
    long connected_pairs = 0;
    long checksum = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        usz position = 2 + 3 * operation;
        long opcode = values[position];
        usz first = (usz)values[position + 1];
        usz second = (usz)values[position + 2];
        long observed = 0;
        if (opcode == 0) {
            usz first_root = find_root(&parent[0], first);
            usz second_root = find_root(&parent[0], second);
            if (first_root != second_root) {
                connected_pairs += set_size[first_root] * set_size[second_root];
                if (set_size[first_root] < set_size[second_root]) {
                    parent[first_root] = (long)second_root;
                    set_size[second_root] += set_size[first_root];
                } else {
                    parent[second_root] = (long)first_root;
                    set_size[first_root] += set_size[second_root];
                }
                components--;
                observed = 1;
            }
        } else if (opcode == 1) {
            observed = (long)(find_root(&parent[0], first) == find_root(&parent[0], second));
        } else {
            observed = (long)components;
        }
        checksum += (long)(operation + 1) * (observed + OBSERVED_OFFSET);
    }
    return checksum + connected_pairs;
}

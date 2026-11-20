module union_find_enumerate;

const usz MAX_ITEMS = 16;
const usz MAX_OPERATIONS = 32;
const usz MAX_INPUT_LENGTH = 99;

fn usz ufe_find(long* parent, usz item) {
    usz root = item;
    while (parent[root] >= 0) root = (usz)parent[root];
    while (item != root) {
        usz next_item = (usz)parent[item];
        parent[item] = (long)root;
        item = next_item;
    }
    return root;
}

fn long ufe_component_mask(long* successor, usz start) {
    ulong mask = 0;
    usz item = start;
    while (true) {
        mask |= (ulong)1 << item;
        item = (usz)successor[item];
        if (item == start) break;
    }
    return (long)mask;
}

fn long union_find_enumerate(long* input, usz length) @export("union_find_enumerate") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long item_count_value = input[0];
    long operation_count_value = input[1];
    if (item_count_value < 1 || item_count_value > (long)MAX_ITEMS ||
        operation_count_value < 0 || operation_count_value > (long)MAX_OPERATIONS) return -1;
    usz item_count = (usz)item_count_value;
    usz operation_count = (usz)operation_count_value;
    if (length != 2 + 3 * operation_count) return -1;

    for (usz operation = 0; operation < operation_count; operation++) {
        usz position = 2 + 3 * operation;
        long opcode = input[position];
        long first = input[position + 1];
        long second = input[position + 2];
        if (opcode == 0) {
            if (first < 0 || first >= item_count_value || second < 0 || second >= item_count_value) return -1;
        } else if (opcode == 1) {
            if (first < 0 || first >= item_count_value || second != 0) return -1;
        } else return -1;
    }

    long[MAX_ITEMS] parent;
    long[MAX_ITEMS] successor;
    for (usz item = 0; item < item_count; item++) {
        parent[item] = -1;
        successor[item] = (long)item;
    }
    long checksum = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        usz position = 2 + 3 * operation;
        long opcode = input[position];
        usz first = (usz)input[position + 1];
        long observed;
        if (opcode == 0) {
            usz left = ufe_find(&parent[0], first);
            usz right = ufe_find(&parent[0], (usz)input[position + 2]);
            observed = 0;
            if (left != right) {
                if (parent[left] > parent[right]) {
                    usz temporary = left;
                    left = right;
                    right = temporary;
                }
                parent[left] += parent[right];
                parent[right] = (long)left;
                long temporary = successor[left];
                successor[left] = successor[right];
                successor[right] = temporary;
                observed = 1;
            }
        } else {
            observed = ufe_component_mask(&successor[0], first);
        }
        checksum += (long)(operation + 1) * (observed + 1);
    }
    return checksum;
}

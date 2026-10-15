module binary_tree_is_sorted_local;

const long MISSING_NODE = -2147483649L;

fn long binary_tree_is_sorted_local(long* nodes, usz length) @export("binary_tree_is_sorted_local") {
    if (length == 0 || length > 255 || nodes == null || nodes[0] == MISSING_NODE) return -1;
    for (usz index = 0; index < length; index++) {
        long value = nodes[index];
        if (value == MISSING_NODE) continue;
        if (value < -2147483648L || value > 2147483647L) return -1;
        if (index > 0) {
            usz parent = (index - 1) / 2;
            if (nodes[parent] == MISSING_NODE) return -1;
            if ((index % 2 == 1 && value > nodes[parent]) ||
                (index % 2 == 0 && value < nodes[parent])) return 0;
        }
    }
    return 1;
}

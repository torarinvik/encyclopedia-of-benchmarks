module bst_iterator;

const usz MAX_NODE_COUNT = 1023;

fn long bst_iterator(long* nodes, usz node_count, long root_index) @export("bst_iterator") {
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return root_index == -1 ? 0 : -1;
    if (nodes == null || root_index < 0 || (usz)root_index >= node_count) return -1;

    long[MAX_NODE_COUNT] iterator_values;
    usz[MAX_NODE_COUNT] stack;
    usz top = 0;
    usz value_count = 0;
    long current = root_index;
    while (current != -1 || top != 0) {
        while (current != -1) {
            if (current < 0 || (usz)current >= node_count || top >= node_count) return -1;
            usz index = (usz)current;
            long left = nodes[3 * index + 1];
            long right = nodes[3 * index + 2];
            if (left < -1 || (left >= 0 && (usz)left >= node_count) ||
                right < -1 || (right >= 0 && (usz)right >= node_count)) return -1;
            stack[top++] = index;
            current = left;
        }
        usz index = stack[--top];
        if (value_count >= node_count) return -1;
        long value = nodes[3 * index];
        if (value < -100000 || value > 100000 ||
            (value_count != 0 && iterator_values[value_count - 1] >= value)) return -1;
        iterator_values[value_count++] = value;
        current = nodes[3 * index + 2];
    }
    if (value_count != node_count) return -1;

    long checksum = 0;
    for (usz next_index = 0; next_index < value_count; next_index++) {
        checksum += ((long)next_index + 1) * (iterator_values[next_index] + 100001);
    }
    return checksum;
}

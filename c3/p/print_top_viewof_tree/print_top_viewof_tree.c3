module print_top_viewof_tree;

const usz MAX_NODES = 1023;

fn long print_top_viewof_tree(long* nodes, usz node_count, long root_index,
        long* output_values, usz output_capacity, usz* column_offsets,
        usz offsets_capacity, usz* queue, usz queue_capacity)
        @export("print_top_viewof_tree") {
    if (node_count > MAX_NODES) return -1;
    if (node_count == 0) {
        if (root_index != -1) return -1;
        if (column_offsets == null || offsets_capacity < 1) return -2;
        column_offsets[0] = 0; return 0;
    }
    if (nodes == null || root_index < 0 || (usz)root_index >= node_count) return -1;
    if (output_values == null || output_capacity < node_count || column_offsets == null ||
        offsets_capacity < node_count + 1 || queue == null || queue_capacity < node_count) return -2;
    usz[MAX_NODES] parents;
    for (usz i = 0; i < node_count; i++) parents[i] = 0;
    for (usz node = 0; node < node_count; node++) {
        usz base = 3 * node;
        long value = nodes[base], left = nodes[base + 1], right = nodes[base + 2];
        if (value < -2147483648 || value > 2147483647 || left < -1 || right < -1 ||
            (left >= 0 && (usz)left >= node_count) || (right >= 0 && (usz)right >= node_count)) return -1;
        if (left >= 0 && ++parents[(usz)left] > 1) return -1;
        if (right >= 0 && ++parents[(usz)right] > 1) return -1;
    }
    if (parents[(usz)root_index] != 0) return -1;
    for (usz node = 0; node < node_count; node++)
        if (node != (usz)root_index && parents[node] != 1) return -1;
    long[MAX_NODES] column;
    bool[MAX_NODES] visited;
    bool[2 * MAX_NODES + 1] seen_column;
    for (usz i = 0; i < MAX_NODES; i++) visited[i] = false;
    for (usz i = 0; i < 2 * MAX_NODES + 1; i++) seen_column[i] = false;
    usz head = 0, tail = 1, reached = 0, written = 0;
    column_offsets[0] = 0;
    queue[0] = (usz)root_index; column[(usz)root_index] = 0; visited[(usz)root_index] = true;
    while (head < tail) {
        usz node = queue[head++]; reached++;
        long coordinate = column[node];
        usz slot = (usz)(coordinate + (long)MAX_NODES);
        if (!seen_column[slot]) {
            seen_column[slot] = true;
            output_values[written] = nodes[3 * node];
            written++;
            column_offsets[written] = written;
        }
        long left = nodes[3 * node + 1], right = nodes[3 * node + 2];
        if (left >= 0) {
            usz child = (usz)left;
            if (visited[child] || tail >= queue_capacity) return -1;
            visited[child] = true; column[child] = coordinate - 1; queue[tail++] = child;
        }
        if (right >= 0) {
            usz child = (usz)right;
            if (visited[child] || tail >= queue_capacity) return -1;
            visited[child] = true; column[child] = coordinate + 1; queue[tail++] = child;
        }
    }
    if (reached != node_count) return -1;
    return (long)written;
}

module directed_dfs_forest_count;

const usz MAX_EDGE_COUNT = 64;
const long MAX_VERTEX_ID = 63;
const usz MAX_NODE_COUNT = 128;
const usz MAX_INPUT_LENGTH = 1 + 2 * MAX_EDGE_COUNT;

fn usz find_last_node(long label, long* labels, usz node_count) {
    usz found = MAX_NODE_COUNT;
    for (usz node = 0; node < node_count; node++) {
        if (labels[node] == label) found = node;
    }
    return found;
}

fn void visit(usz current, usz edge_count, usz* edge_starts, usz* edge_ends, bool* visited) {
    visited[current] = true;
    for (usz edge = 0; edge < edge_count; edge++) {
        usz destination = edge_ends[edge];
        if (edge_starts[edge] == current && !visited[destination])
            visit(destination, edge_count, edge_starts, edge_ends, visited);
    }
}

fn long directed_dfs_forest_count(long* input, usz length) @export("directed_dfs_forest_count") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH + 1) return -1;
    long edge_count_value = input[0];
    if (edge_count_value < 0 || edge_count_value > (long)MAX_EDGE_COUNT) return -1;
    usz edge_count = (usz)edge_count_value;
    if (length != 1 + 2 * edge_count) return -1;

    long[MAX_NODE_COUNT] labels = zeroed;
    usz[MAX_EDGE_COUNT] edge_starts, edge_ends;
    usz node_count = 0;
    for (usz edge = 0; edge < edge_count; edge++) {
        long start_label = input[1 + 2 * edge];
        long end_label = input[2 + 2 * edge];
        if (start_label < 0 || start_label > MAX_VERTEX_ID
            || end_label < 0 || end_label > MAX_VERTEX_ID) return -1;

        usz start = find_last_node(start_label, &labels[0], node_count);
        usz end;
        if (start_label == end_label) {
            if (start == MAX_NODE_COUNT) {
                start = node_count;
                labels[node_count++] = start_label;
            }
            end = node_count;
            labels[node_count++] = end_label;
        } else {
            end = find_last_node(end_label, &labels[0], node_count);
            if (start == MAX_NODE_COUNT) {
                start = node_count;
                labels[node_count++] = start_label;
            }
            if (end == MAX_NODE_COUNT) {
                end = node_count;
                labels[node_count++] = end_label;
            }
        }
        edge_starts[edge] = start;
        edge_ends[edge] = end;
    }

    bool[MAX_NODE_COUNT] marked = zeroed;
    long roots = 0;
    for (usz root = 0; root < node_count; root++) {
        if (marked[root]) continue;
        bool[MAX_NODE_COUNT] visited = zeroed;
        visit(root, edge_count, &edge_starts[0], &edge_ends[0], &visited[0]);
        for (usz node = 0; node < node_count; node++) {
            if (visited[node]) marked[node] = true;
        }
        roots++;
    }
    return roots;
}

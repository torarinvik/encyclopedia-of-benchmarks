module minimum_spanning_tree_kruskal;

const usz MAX_VERTICES = 64;
const usz MAX_EDGES = 4096;
const usz MAX_INPUT_LENGTH = 2 + 3 * MAX_EDGES;

fn bool edge_less(long* input, long left, long right) {
    long left_weight = input[2 + 3 * left + 2];
    long right_weight = input[2 + 3 * right + 2];
    return left_weight < right_weight || (left_weight == right_weight && left < right);
}

fn void sift_down(long* input, long* order, long root_start, long end) {
    long root = root_start;
    while (root * 2 + 1 < end) {
        long child = root * 2 + 1;
        if (child + 1 < end && edge_less(input, order[child], order[child + 1])) child += 1;
        if (!edge_less(input, order[root], order[child])) break;
        long temporary = order[root];
        order[root] = order[child];
        order[child] = temporary;
        root = child;
    }
}

fn void heap_sort(long* input, long* order, long count) {
    long start = count / 2;
    while (start > 0) {
        start -= 1;
        sift_down(input, order, start, count);
    }
    long ending = count;
    while (ending > 1) {
        ending -= 1;
        long temporary = order[0];
        order[0] = order[ending];
        order[ending] = temporary;
        sift_down(input, order, 0, ending);
    }
}

fn long find_root(long* parent, long node_input) {
    long node = node_input;
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long minimum_spanning_tree_kruskal(long* input, usz length, char* output, usz capacity)
    @export("minimum_spanning_tree_kruskal") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long raw_vertices = input[0];
    long raw_edges = input[1];
    if (raw_vertices < 0 || raw_vertices > (long)MAX_VERTICES ||
        raw_edges < 0 || raw_edges > (long)MAX_EDGES) return -1;
    long vertex_count = raw_vertices;
    long edge_count = raw_edges;
    if (length != 2 + 3 * (usz)edge_count) return -1;

    long[MAX_EDGES] order;
    for (long index = 0; index < edge_count; index += 1) {
        usz offset = 2 + 3 * (usz)index;
        long u = input[offset];
        long v = input[offset + 1];
        if (u < 0 || u >= raw_vertices || v < 0 || v >= raw_vertices) return -1;
        order[index] = index;
    }
    heap_sort(input, &order[0], edge_count);

    long[MAX_VERTICES] parent;
    for (long vertex = 0; vertex < vertex_count; vertex += 1) parent[vertex] = vertex;
    long[MAX_VERTICES] accepted;
    long accepted_count = 0;
    for (long index = 0; index < edge_count; index += 1) {
        long edge_index = order[index];
        usz offset = 2 + 3 * (usz)edge_index;
        long left_root = find_root(&parent[0], input[offset]);
        long right_root = find_root(&parent[0], input[offset + 1]);
        if (left_root != right_root) {
            accepted[accepted_count] = edge_index;
            accepted_count += 1;
            parent[left_root] = right_root;
        }
    }

    usz byte_count = (usz)accepted_count * 24;
    if (output == null || capacity < byte_count) return -2;
    for (long index = 0; index < accepted_count; index += 1) {
        usz input_offset = 2 + 3 * (usz)accepted[index];
        usz output_offset = (usz)index * 24;
        put_i64_le(output, output_offset, input[input_offset]);
        put_i64_le(output, output_offset + 8, input[input_offset + 1]);
        put_i64_le(output, output_offset + 16, input[input_offset + 2]);
    }
    return (long)byte_count;
}

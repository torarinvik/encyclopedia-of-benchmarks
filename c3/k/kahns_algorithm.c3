module kahns_algorithm;

const usz MAX_VERTICES = 32;
const usz MAX_EDGES = 128;
const usz MAX_INPUT_LENGTH = 257;
const long I32_MIN_VALUE = -2147483648;
const long I32_MAX_VALUE = 2147483647;

fn int find_vertex(int* labels, usz vertex_count, int label) {
    for (usz i = 0; i < vertex_count; i++) if (labels[i] == label) return (int)i;
    return -1;
}

fn long kahns_algorithm(long* input, usz length, char* output, usz capacity)
        @export("kahns_algorithm") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long edge_count_value = input[0];
    if (edge_count_value < 0 || edge_count_value > (long)MAX_EDGES) return -1;
    usz edge_count = (usz)edge_count_value;
    if (length != 1 + 2 * edge_count) return -1;

    int[MAX_VERTICES] labels = zeroed;
    int[MAX_VERTICES] first_edge, tail_edge;
    int[MAX_EDGES] next_edge;
    usz[MAX_EDGES] to;
    usz[MAX_VERTICES] indegree = zeroed;
    usz vertex_count = 0;
    for (usz vertex = 0; vertex < MAX_VERTICES; vertex++) {
        first_edge[vertex] = -1;
        tail_edge[vertex] = -1;
    }
    for (usz edge = 0; edge < edge_count; edge++) {
        long from_value = input[1 + 2 * edge];
        long to_value = input[2 + 2 * edge];
        if (from_value < I32_MIN_VALUE || from_value > I32_MAX_VALUE ||
            to_value < I32_MIN_VALUE || to_value > I32_MAX_VALUE) return -1;
        int from_label = (int)from_value;
        int to_label = (int)to_value;
        int from_index = find_vertex(&labels[0], vertex_count, from_label);
        if (from_index < 0) {
            if (vertex_count >= MAX_VERTICES) return -1;
            from_index = (int)vertex_count;
            labels[vertex_count++] = from_label;
        }
        int to_index = find_vertex(&labels[0], vertex_count, to_label);
        if (to_index < 0) {
            if (vertex_count >= MAX_VERTICES) return -1;
            to_index = (int)vertex_count;
            labels[vertex_count++] = to_label;
        }
        to[edge] = (usz)to_index;
        next_edge[edge] = -1;
        if (first_edge[(usz)from_index] < 0) first_edge[(usz)from_index] = (int)edge;
        else next_edge[(usz)tail_edge[(usz)from_index]] = (int)edge;
        tail_edge[(usz)from_index] = (int)edge;
        indegree[(usz)to_index]++;
    }

    usz[MAX_VERTICES] queue, order;
    usz queue_head = 0, queue_tail = 0, order_count = 0;
    for (usz vertex = 0; vertex < vertex_count; vertex++)
        if (indegree[vertex] == 0) queue[queue_tail++] = vertex;
    if (vertex_count > 0 && queue_tail != 1) return -1;
    while (queue_head < queue_tail) {
        if (queue_tail - queue_head != 1) return -1;
        usz current = queue[queue_head++];
        order[order_count++] = current;
        for (int outgoing = first_edge[current]; outgoing >= 0; outgoing = next_edge[(usz)outgoing]) {
            usz adjacent = to[(usz)outgoing];
            if (indegree[adjacent] == 0) return -1;
            indegree[adjacent]--;
            if (indegree[adjacent] == 0) queue[queue_tail++] = adjacent;
        }
    }
    if (order_count != vertex_count) return -1;

    usz output_bytes = 4 * order_count;
    if (output == null || capacity < output_bytes) return -2;
    for (usz index = 0; index < order_count; index++) {
        uint bits = (uint)labels[order[index]];
        for (usz byte = 0; byte < 4; byte++) {
            output[4 * index + byte] = (char)(bits & 255);
            bits >>= 8;
        }
    }
    return (long)output_bytes;
}

module k_shortest_walk;

const usz MAX_VERTICES = 6;
const usz MAX_EDGES = 12;
const usz MAX_K = 8;
const usz MAX_INPUT_LENGTH = 41;
const usz MAX_FRONTIER = 97;

fn void write_i64(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (uint8)(bits >> (8 * byte));
}

fn long k_shortest_walk(long* input, usz length, uint8* output, usz output_capacity)
        @export("k_shortest_walk") {
    if (input == null || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0];
    long m_value = input[1];
    long source_value = input[2];
    long target_value = input[3];
    long k_value = input[4];
    if (n_value < 1 || n_value > 6 || m_value < 0 || m_value > 12 ||
        k_value < 1 || k_value > 8 || source_value < 0 || source_value >= n_value ||
        target_value < 0 || target_value >= n_value) return -1;
    usz n = (usz)n_value;
    usz m = (usz)m_value;
    usz source = (usz)source_value;
    usz target = (usz)target_value;
    usz k = (usz)k_value;
    if (length != 5 + 3 * m) return -1;

    long[MAX_VERTICES] head;
    long[MAX_EDGES] edge_to;
    long[MAX_EDGES] edge_weight;
    long[MAX_EDGES] edge_next;
    for (usz vertex = 0; vertex < n; vertex++) head[vertex] = -1;
    for (usz edge = 0; edge < m; edge++) {
        long u = input[5 + 3 * edge];
        long v = input[6 + 3 * edge];
        long weight = input[7 + 3 * edge];
        if (u < 0 || u >= n_value || v < 0 || v >= n_value || weight < 0 || weight > 1000) return -1;
        edge_to[edge] = v;
        edge_weight[edge] = weight;
        edge_next[edge] = head[(usz)u];
        head[(usz)u] = (long)edge;
    }
    if (output == null || output_capacity < 8 * k) return -2;

    long[MAX_FRONTIER] queue_distance;
    long[MAX_FRONTIER] queue_vertex;
    long[MAX_FRONTIER] queue_order;
    long[MAX_VERTICES] expanded = zeroed;
    long[MAX_K] answers;
    usz queue_count = 1;
    usz answer_count = 0;
    long next_order = 1;
    queue_distance[0] = 0;
    queue_vertex[0] = (long)source;
    queue_order[0] = 0;

    while (queue_count > 0 && answer_count < k) {
        long distance = queue_distance[0];
        usz vertex = (usz)queue_vertex[0];
        for (usz slot = 1; slot < queue_count; slot++) {
            queue_distance[slot - 1] = queue_distance[slot];
            queue_vertex[slot - 1] = queue_vertex[slot];
            queue_order[slot - 1] = queue_order[slot];
        }
        queue_count--;
        if (expanded[vertex] >= (long)k) continue;
        expanded[vertex]++;
        if (vertex == target) {
            answers[answer_count++] = distance;
            if (answer_count == k) break;
        }
        for (long edge = head[vertex]; edge >= 0; edge = edge_next[(usz)edge]) {
            usz edge_index = (usz)edge;
            long candidate_distance = distance + edge_weight[edge_index];
            long candidate_vertex = edge_to[edge_index];
            long candidate_order = next_order++;
            usz position = queue_count;
            while (position > 0 &&
                    (queue_distance[position - 1] > candidate_distance ||
                     (queue_distance[position - 1] == candidate_distance &&
                      queue_order[position - 1] > candidate_order))) {
                queue_distance[position] = queue_distance[position - 1];
                queue_vertex[position] = queue_vertex[position - 1];
                queue_order[position] = queue_order[position - 1];
                position--;
            }
            queue_distance[position] = candidate_distance;
            queue_vertex[position] = candidate_vertex;
            queue_order[position] = candidate_order;
            queue_count++;
        }
    }
    while (answer_count < k) answers[answer_count++] = -1;
    for (usz index = 0; index < k; index++) write_i64(output, 8 * index, answers[index]);
    return (long)(8 * k);
}

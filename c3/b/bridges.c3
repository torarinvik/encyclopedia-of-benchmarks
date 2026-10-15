module bridges;

const usz MAX_VERTEX_COUNT = 64;
const usz MAX_EDGE_COUNT = 2047;
const usz MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGE_COUNT;

fn void visit_vertex(ulong* adjacency, ulong* bridge_mask, long* discovery, long* low,
    long* parent, usz vertex_count, usz vertex, usz* time) {
    discovery[vertex] = (long)(*time);
    low[vertex] = (long)(*time);
    (*time)++;
    for (usz neighbor = 0; neighbor < vertex_count; neighbor++) {
        if ((adjacency[vertex] & (1ul << (ulong)neighbor)) == 0ul) continue;
        if (discovery[neighbor] == -1) {
            parent[neighbor] = (long)vertex;
            visit_vertex(adjacency, bridge_mask, discovery, low, parent,
                vertex_count, neighbor, time);
            if (low[neighbor] < low[vertex]) low[vertex] = low[neighbor];
            if (low[neighbor] > discovery[vertex]) {
                bridge_mask[vertex] |= 1ul << (ulong)neighbor;
                bridge_mask[neighbor] |= 1ul << (ulong)vertex;
            }
        } else if ((long)neighbor != parent[vertex] && discovery[neighbor] < low[vertex]) {
            low[vertex] = discovery[neighbor];
        }
    }
}

fn long bridges(long* input, usz length, char* output, usz output_capacity)
    @export("bridges") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH || input[0] < 0 ||
        input[0] > (long)MAX_VERTEX_COUNT || input[1] < 0 || input[1] > (long)MAX_EDGE_COUNT) return -1;
    usz vertex_count = (usz)input[0];
    usz edge_count = (usz)input[1];
    if (length != 2 + 2 * edge_count) return -1;
    ulong[MAX_VERTEX_COUNT] adjacency;
    for (usz vertex = 0; vertex < MAX_VERTEX_COUNT; vertex++) adjacency[vertex] = 0ul;
    for (usz edge = 0; edge < edge_count; edge++) {
        long left_value = input[2 + 2 * edge];
        long right_value = input[3 + 2 * edge];
        if (left_value < 0 || right_value < 0 || (ulong)left_value >= (ulong)vertex_count ||
            (ulong)right_value >= (ulong)vertex_count) return -1;
        usz left = (usz)left_value;
        usz right = (usz)right_value;
        adjacency[left] |= 1ul << (ulong)right;
        adjacency[right] |= 1ul << (ulong)left;
    }
    ulong[MAX_VERTEX_COUNT] bridge_mask;
    long[MAX_VERTEX_COUNT] discovery, low, parent;
    for (usz vertex = 0; vertex < MAX_VERTEX_COUNT; vertex++) {
        bridge_mask[vertex] = 0ul;
        discovery[vertex] = -1;
        low[vertex] = 0;
        parent[vertex] = -1;
    }
    usz time = 0;
    for (usz vertex = 0; vertex < vertex_count; vertex++)
        if (discovery[vertex] == -1)
            visit_vertex(&adjacency[0], &bridge_mask[0], &discovery[0], &low[0],
                &parent[0], vertex_count, vertex, &time);
    usz bridge_count = 0;
    for (usz left = 0; left < vertex_count; left++)
        for (usz right = left + 1; right < vertex_count; right++)
            if ((bridge_mask[left] & (1ul << (ulong)right)) != 0ul) bridge_count++;
    usz output_length = 2 * bridge_count;
    if (output_capacity < output_length || (output_length != 0 && output == null)) return -2;
    usz position = 0;
    for (usz left = 0; left < vertex_count; left++)
        for (usz right = left + 1; right < vertex_count; right++)
            if ((bridge_mask[left] & (1ul << (ulong)right)) != 0ul) {
                output[position] = (char)left;
                output[position + 1] = (char)right;
                position += 2;
            }
    return (long)output_length;
}

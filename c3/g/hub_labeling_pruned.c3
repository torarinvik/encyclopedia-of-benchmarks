module hub_labeling_pruned;

const usz MAX_VERTICES = 8;
const usz MAX_EDGES = 28;
const usz MAX_INPUT = 66;
const usz MAX_FIELDS = 73;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn bool unique_shortest_paths(bool* adjacency, usz n) {
    for (usz source = 0; source < n; source += 1) {
        long[MAX_VERTICES] distance = {};
        ubyte[MAX_VERTICES] ways = {};
        usz[MAX_VERTICES] queue = {};
        for (usz i = 0; i < n; i += 1) distance[i] = -1;
        usz head = 0, tail = 0;
        distance[source] = 0; ways[source] = 1; queue[tail] = source; tail += 1;
        while (head < tail) {
            usz vertex = queue[head]; head += 1;
            for (usz neighbor = 0; neighbor < n; neighbor += 1) {
                if (!adjacency[vertex * MAX_VERTICES + neighbor]) continue;
                if (distance[neighbor] < 0) {
                    distance[neighbor] = distance[vertex] + 1;
                    ways[neighbor] = ways[vertex];
                    queue[tail] = neighbor; tail += 1;
                } else if (distance[neighbor] == distance[vertex] + 1) {
                    usz sum = (usz)ways[neighbor] + (usz)ways[vertex];
                    ways[neighbor] = (ubyte)(sum > 1 ? 2 : sum);
                }
            }
        }
        for (usz vertex = 0; vertex < n; vertex += 1) if (ways[vertex] != 1) return false;
    }
    return true;
}

long hub_labeling_pruned(long* input, usz length, char* output, usz capacity) @export("hub_labeling_pruned") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_VERTICES || m_value < 0 || m_value > (long)MAX_EDGES) return -1;
    usz n = (usz)n_value, m = (usz)m_value;
    if (length != 2 + n + 2 * m) return -1;
    bool[MAX_VERTICES] seen_order = {};
    for (usz i = 0; i < n; i += 1) {
        long vertex = input[2 + i];
        if (vertex < 0 || (ulong)vertex >= n || seen_order[(usz)vertex]) return -1;
        seen_order[(usz)vertex] = true;
    }
    bool[MAX_VERTICES * MAX_VERTICES] adjacency = {};
    long previous_left = -1, previous_right = -1;
    for (usz edge = 0; edge < m; edge += 1) {
        long left = input[2 + n + 2 * edge], right = input[3 + n + 2 * edge];
        if (left < 0 || right <= left || (ulong)right >= n || left < previous_left
            || (left == previous_left && right <= previous_right)) return -1;
        previous_left = left; previous_right = right;
        adjacency[(usz)left * MAX_VERTICES + (usz)right] = true;
        adjacency[(usz)right * MAX_VERTICES + (usz)left] = true;
    }
    if (!unique_shortest_paths(&adjacency[0], n)) return -1;

    short[MAX_VERTICES * MAX_VERTICES] labels = {};
    for (usz i = 0; i < MAX_VERTICES * MAX_VERTICES; i += 1) labels[i] = -1;
    for (usz order_index = 0; order_index < n; order_index += 1) {
        usz hub = (usz)input[2 + order_index];
        long[MAX_VERTICES] distance = {};
        usz[MAX_VERTICES] queue = {};
        for (usz i = 0; i < n; i += 1) distance[i] = -1;
        usz head = 0, tail = 0;
        distance[hub] = 0; queue[tail] = hub; tail += 1;
        while (head < tail) {
            usz vertex = queue[head]; head += 1;
            long estimate = 2 * (long)MAX_VERTICES;
            for (usz common = 0; common < n; common += 1) {
                short from_hub = labels[hub * MAX_VERTICES + common];
                short from_vertex = labels[vertex * MAX_VERTICES + common];
                if (from_hub >= 0 && from_vertex >= 0 && (long)from_hub + (long)from_vertex < estimate)
                    estimate = (long)from_hub + (long)from_vertex;
            }
            if (estimate <= distance[vertex]) continue;
            labels[vertex * MAX_VERTICES + hub] = (short)distance[vertex];
            for (usz neighbor = 0; neighbor < n; neighbor += 1) {
                if (adjacency[vertex * MAX_VERTICES + neighbor] && distance[neighbor] < 0) {
                    distance[neighbor] = distance[vertex] + 1;
                    queue[tail] = neighbor; tail += 1;
                }
            }
        }
    }
    long[MAX_FIELDS] fields = {};
    usz field_count = 0;
    fields[field_count] = (long)n; field_count += 1;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        usz count_index = field_count; field_count += 1;
        long count = 0;
        for (usz hub = 0; hub < n; hub += 1) {
            short value = labels[vertex * MAX_VERTICES + hub];
            if (value >= 0) { fields[field_count] = (long)hub | ((long)value << 8); field_count += 1; count += 1; }
        }
        fields[count_index] = count;
    }
    usz bytes = field_count * 8;
    if (output == null || capacity < bytes) return -2;
    char[MAX_FIELDS * 8] staged = {};
    for (usz i = 0; i < field_count; i += 1) store_i64_le(&staged[0], 8 * i, fields[i]);
    for (usz i = 0; i < bytes; i += 1) output[i] = staged[i];
    return (long)bytes;
}

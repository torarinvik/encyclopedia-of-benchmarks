module connected_components_of_complement_graph;

const usz MAX_N = 64;
const usz MAX_M = MAX_N * (MAX_N - 1) / 2;
const usz MAX_INPUT_VALUES = 2 + 2 * MAX_M;
const usz MAX_OUTPUT_VALUES = 1 + 2 * MAX_N;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long connected_components_of_complement_graph(long* input, usz length,
    char* output, usz capacity) @export("connected_components_of_complement_graph") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    long n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || m_value < 0) return -1;
    if (m_value > n_value * (n_value - 1) / 2) return -1;
    usz n = (usz)n_value, m = (usz)m_value;
    if (length != 2 + 2 * m) return -1;

    ulong[MAX_N] graph = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long left_value = input[2 + 2 * edge];
        long right_value = input[3 + 2 * edge];
        if (left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value) return -1;
        usz left = (usz)left_value, right = (usz)right_value;
        ulong bit = (ulong)1 << right;
        if ((graph[left] & bit) != 0) return -1;
        graph[left] |= bit;
        graph[right] |= (ulong)1 << left;
    }

    usz[MAX_N] remaining, queue;
    long[MAX_N] label;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        remaining[vertex] = vertex;
        label[vertex] = -1;
    }
    usz remaining_count = n, component_count = 0;
    while (remaining_count > 0) {
        remaining_count -= 1;
        usz root = remaining[remaining_count];
        label[root] = (long)component_count;
        usz head = 0, tail = 1;
        queue[0] = root;
        while (head < tail) {
            usz current = queue[head];
            head += 1;
            usz position = 0;
            while (position < remaining_count) {
                usz candidate = remaining[position];
                if (((graph[current] >> candidate) & 1) != 0) {
                    position += 1;
                } else {
                    remaining_count -= 1;
                    remaining[position] = remaining[remaining_count];
                    label[candidate] = (long)component_count;
                    queue[tail] = candidate;
                    tail += 1;
                }
            }
        }
        component_count += 1;
    }

    long[MAX_OUTPUT_VALUES] staged;
    bool[MAX_N] emitted = zeroed;
    usz used = 0;
    staged[used] = (long)component_count;
    used += 1;
    for (usz first = 0; first < n; first += 1) {
        usz component = (usz)label[first];
        if (emitted[component]) continue;
        emitted[component] = true;
        usz component_size = 0;
        for (usz vertex = 0; vertex < n; vertex += 1)
            if ((usz)label[vertex] == component) component_size += 1;
        staged[used] = (long)component_size;
        used += 1;
        for (usz vertex = 0; vertex < n; vertex += 1) {
            if ((usz)label[vertex] == component) {
                staged[used] = (long)vertex;
                used += 1;
            }
        }
    }

    usz required = 8 * used;
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index < used; index += 1)
        store_i64_le(output, 8 * index, staged[index]);
    return (long)required;
}

module list_ranking_independent_set_contraction;
const usz MAX_N = 16; const usz MAX_INPUT = 34; const usz MAX_OUTPUT = 128;

fn void put64(char* output, usz position, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[position + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long list_ranking_independent_set_contraction(long* input, usz length, char* output,
                                               usz capacity) @export("list_ranking_independent_set_contraction") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long n_value = input[0], head_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || length != 2 + 2 * (usz)n_value ||
        head_value < 0 || head_value >= n_value) return -1;
    usz n = (usz)n_value, head = (usz)head_value;
    long[MAX_N] weight = zeroed, successor = zeroed;
    usz[MAX_N] indegree = zeroed;
    usz tail_count = 0;
    for (usz node = 0; node < n; node += 1) {
        weight[node] = input[2 + node];
        successor[node] = input[2 + n + node];
        if (weight[node] < 1 || weight[node] > 10000 ||
            successor[node] < -1 || successor[node] >= n_value) return -1;
        if (successor[node] == -1) tail_count += 1;
        else {
            usz next = (usz)successor[node];
            indegree[next] += 1;
            if (indegree[next] > 1) return -1;
        }
    }
    if (tail_count != 1 || indegree[head] != 0) return -1;

    usz[MAX_N] path = zeroed;
    bool[MAX_N] seen = zeroed;
    usz path_length = 0;
    long node = head_value;
    while (node != -1) {
        usz index = (usz)node;
        if (seen[index] || path_length == n) return -1;
        seen[index] = true;
        path[path_length] = index;
        path_length += 1;
        node = successor[index];
    }
    if (path_length != n) return -1;
    usz output_bytes = 8 * n;
    if (output == null || capacity < output_bytes) return -2;

    usz[MAX_N] removed_node = zeroed, removed_successor = zeroed;
    long[MAX_N] old_successor_weight = zeroed;
    usz removed_count = 0;
    while (path_length > 1) {
        usz[3] counts = zeroed;
        for (usz position = 0; position + 1 < path_length; position += 1)
            counts[position % 3] += 1;
        usz color = 0;
        for (usz candidate = 1; candidate < 3; candidate += 1)
            if (counts[candidate] > counts[color]) color = candidate;
        usz write = 0;
        for (usz position = 0; position < path_length; position += 1) {
            usz current = path[position];
            if (position + 1 < path_length && position % 3 == color) {
                usz next = path[position + 1];
                removed_node[removed_count] = current;
                removed_successor[removed_count] = next;
                old_successor_weight[removed_count] = weight[next];
                removed_count += 1;
                weight[next] += weight[current];
            } else {
                path[write] = current;
                write += 1;
            }
        }
        if (write == path_length) return -1;
        path_length = write;
    }

    long[MAX_N] rank = zeroed;
    rank[path[0]] = weight[path[0]];
    while (removed_count > 0) {
        removed_count -= 1;
        usz current = removed_node[removed_count], next = removed_successor[removed_count];
        rank[current] = rank[next] - old_successor_weight[removed_count];
    }
    char[MAX_OUTPUT] staged = zeroed;
    for (usz index = 0; index < n; index += 1) put64(&staged[0], 8 * index, rank[index]);
    for (usz index = 0; index < output_bytes; index += 1) output[index] = staged[index];
    return (long)output_bytes;
}

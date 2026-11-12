module common_interval_decomposition_tree;

const usz MAX_N = 48;
const usz MAX_NODES = 2 * MAX_N - 1;
const usz GRID = MAX_N * MAX_N;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn bool intervals_overlap(int left_a, int right_a, int left_b, int right_b) {
    return (left_a < left_b && left_b <= right_a && right_a < right_b) ||
           (left_b < left_a && left_a <= right_b && right_b < right_a);
}

fn long common_interval_decomposition_tree(long* input, usz length,
    char* output, usz capacity) @export("common_interval_decomposition_tree") {
    if (input == null || length < 2 || length > 1 + MAX_N) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != n + 1) return -1;

    bool[MAX_N] seen;
    for (usz i = 0; i < MAX_N; i += 1) seen[i] = false;
    for (usz i = 0; i < n; i += 1) {
        long value = input[i + 1];
        if (value < 0 || value >= (long)n || seen[(usz)value]) return -1;
        seen[(usz)value] = true;
    }

    bool[GRID] connected;
    bool[GRID] strong;
    for (usz i = 0; i < GRID; i += 1) {
        connected[i] = false;
        strong[i] = false;
    }
    for (usz left = 0; left < n; left += 1) {
        long minimum = (long)n;
        long maximum = -1;
        for (usz right = left; right < n; right += 1) {
            long value = input[right + 1];
            if (value < minimum) minimum = value;
            if (value > maximum) maximum = value;
            usz slot = left * MAX_N + right;
            if (maximum - minimum == (long)(right - left)) {
                connected[slot] = true;
                strong[slot] = true;
            }
        }
    }

    for (usz left_a = 0; left_a < n; left_a += 1) {
        for (usz right_a = left_a; right_a < n; right_a += 1) {
            usz slot_a = left_a * MAX_N + right_a;
            if (!connected[slot_a]) continue;
            for (usz left_b = 0; left_b < n; left_b += 1) {
                for (usz right_b = left_b; right_b < n; right_b += 1) {
                    usz slot_b = left_b * MAX_N + right_b;
                    if (slot_b <= slot_a || !connected[slot_b]) continue;
                    if (intervals_overlap((int)left_a, (int)right_a,
                                          (int)left_b, (int)right_b)) {
                        strong[slot_a] = false;
                        strong[slot_b] = false;
                    }
                }
            }
        }
    }

    int[MAX_NODES] node_left;
    int[MAX_NODES] node_right;
    int[MAX_NODES] parent;
    int[MAX_NODES] node_type;
    usz node_count = 0;
    usz span = n;
    while (span > 0) {
        for (usz left = 0; left + span <= n; left += 1) {
            usz right = left + span - 1;
            if (!strong[left * MAX_N + right]) continue;
            node_left[node_count] = (int)left;
            node_right[node_count] = (int)right;
            node_count += 1;
        }
        span -= 1;
    }
    if (node_count == 0 || node_count > MAX_NODES) return -1;

    for (usz node = 0; node < node_count; node += 1) {
        int node_span = node_right[node] - node_left[node] + 1;
        int best_span = (int)n + 1;
        parent[node] = -1;
        for (usz candidate = 0; candidate < node_count; candidate += 1) {
            int candidate_span = node_right[candidate] - node_left[candidate] + 1;
            if (candidate_span > node_span && candidate_span < best_span &&
                node_left[candidate] <= node_left[node] &&
                node_right[node] <= node_right[candidate]) {
                parent[node] = (int)candidate;
                best_span = candidate_span;
            }
        }
    }

    for (usz node = 0; node < node_count; node += 1) {
        int[MAX_N] children;
        usz child_count = 0;
        for (usz child = 0; child < node_count; child += 1) {
            if (parent[child] != (int)node) continue;
            usz at = child_count;
            while (at > 0 && node_left[(usz)children[at - 1]] > node_left[child]) {
                children[at] = children[at - 1];
                at -= 1;
            }
            children[at] = (int)child;
            child_count += 1;
        }

        node_type[node] = 0;
        for (usz first = 0; first < child_count && node_type[node] == 0; first += 1) {
            for (usz last = first; last < child_count; last += 1) {
                int left = node_left[(usz)children[first]];
                int right = node_right[(usz)children[last]];
                long minimum = (long)n;
                long maximum = -1;
                for (int position = left; position <= right; position += 1) {
                    long value = input[(usz)position + 1];
                    if (value < minimum) minimum = value;
                    if (value > maximum) maximum = value;
                }
                if (maximum - minimum != (long)(right - left)) {
                    node_type[node] = 1;
                    break;
                }
            }
        }
    }

    usz output_bytes = (1 + 4 * node_count) * 8;
    if (output == null || capacity < output_bytes) return -2;
    store_i64_le(output, 0, (long)node_count);
    for (usz node = 0; node < node_count; node += 1) {
        usz offset = 8 + 32 * node;
        store_i64_le(output, offset, (long)parent[node]);
        store_i64_le(output, offset + 8, (long)node_left[node]);
        store_i64_le(output, offset + 16, (long)node_right[node]);
        store_i64_le(output, offset + 24, (long)node_type[node]);
    }
    return (long)output_bytes;
}

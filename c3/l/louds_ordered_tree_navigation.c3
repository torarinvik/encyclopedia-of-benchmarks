module louds_ordered_tree_navigation;

const usz MAX_NODES = 32;
const usz MAX_QUERIES = 32;
const usz MAX_INPUT_WORDS = 130;
const usz MAX_OUTPUT_WORDS = 4 + MAX_QUERIES;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long louds_ordered_tree_navigation(long* input, usz length,
    char* output, usz capacity) @export("louds_ordered_tree_navigation") {
    if (input == null || length < 2 || length > MAX_INPUT_WORDS) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_NODES ||
        q_value < 0 || q_value > (long)MAX_QUERIES) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length != 2 + (n - 1) + 3 * q) return -1;

    usz[MAX_NODES] parent = zeroed;
    for (usz vertex = 1; vertex < n; vertex += 1) {
        long value = input[1 + vertex];
        if (value < 0 || (ulong)value >= vertex) return -1;
        parent[vertex] = (usz)value;
    }
    usz query_base = n + 1;
    for (usz index = 0; index < q; index += 1) {
        usz offset = query_base + 3 * index;
        long opcode = input[offset], node = input[offset + 1], arg = input[offset + 2];
        if (node < 0 || node >= n_value) return -1;
        if (opcode == 0 || opcode == 1) {
            if (arg != 0) return -1;
        } else if (opcode == 2) {
            if (arg < 0 || (ulong)arg > n) return -1;
        } else return -1;
    }

    usz[MAX_NODES] order;
    usz order_count = 1, cursor = 0;
    order[0] = 0;
    while (cursor < order_count) {
        usz vertex = order[cursor];
        cursor += 1;
        for (usz child = 1; child < n; child += 1) {
            if (parent[child] == vertex) {
                order[order_count] = child;
                order_count += 1;
            }
        }
    }
    if (order_count != n) return -1;

    usz[MAX_NODES] degree = zeroed;
    for (usz node = 0; node < n; node += 1)
        for (usz child = 1; child < n; child += 1)
            if (parent[child] == order[node]) degree[node] += 1;

    ulong packed = 0;
    usz bit_length = 0;
    for (usz node = 0; node < n; node += 1) {
        for (usz child = 0; child < degree[node]; child += 1) {
            packed |= ((ulong)1) << bit_length;
            bit_length += 1;
        }
        bit_length += 1;
    }

    usz[MAX_NODES] decoded = zeroed;
    usz[MAX_NODES + 1] rank_prefix = zeroed;
    usz bit_position = 0, previous_zero = (usz)-1;
    for (usz node = 0; node < n; node += 1) {
        while (bit_position < bit_length && ((packed >> bit_position) & 1) != 0)
            bit_position += 1;
        decoded[node] = bit_position - previous_zero - 1;
        previous_zero = bit_position;
        bit_position += 1;
        rank_prefix[node + 1] = rank_prefix[node] + decoded[node];
    }

    long[MAX_OUTPUT_WORDS] words = zeroed;
    words[0] = n_value;
    words[1] = (long)bit_length;
    words[2] = (long)packed;
    words[3] = q_value;
    for (usz index = 0; index < q; index += 1) {
        usz offset = query_base + 3 * index;
        long opcode = input[offset], node_value = input[offset + 1], arg = input[offset + 2];
        usz node = (usz)node_value;
        long answer = -1;
        if (opcode == 0) answer = (long)decoded[node];
        else if (opcode == 1) {
            if (node != 0) {
                for (usz candidate = 0; candidate < n; candidate += 1) {
                    if (rank_prefix[candidate + 1] >= node) {
                        answer = (long)candidate;
                        break;
                    }
                }
            }
        } else {
            usz child_rank = (usz)arg;
            if (child_rank < decoded[node])
                answer = (long)(1 + rank_prefix[node] + child_rank);
        }
        words[4 + index] = answer;
    }
    usz required = 8 * (4 + q);
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index < 4 + q; index += 1)
        store_i64_le(output, 8 * index, words[index]);
    return (long)required;
}

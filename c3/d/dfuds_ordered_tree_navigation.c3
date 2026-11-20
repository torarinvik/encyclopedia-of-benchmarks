module dfuds_ordered_tree_navigation;

const usz MAX_N = 31;
const usz MAX_Q = 32;
const usz MAX_INPUT = 129;
const usz MAX_BITS = 2 * MAX_N;
const usz MAX_OUTPUT_WORDS = 4 + MAX_Q;

fn bool dfuds_bit_at(ulong bits, usz position) {
    ((bits >> (position - 1)) & 1) != 0
}

fn usz dfuds_find_close(ulong bits, usz bit_length, usz start) {
    int balance = 0;
    for (usz position = start; position <= bit_length; position += 1) {
        if (dfuds_bit_at(bits, position)) balance += 1;
        else balance -= 1;
        if (balance == 0) return position;
    }
    bit_length + 1
}

fn usz dfuds_find_open(ulong bits, usz position) {
    if (dfuds_bit_at(bits, position)) return position;
    int balance = 0;
    usz candidate = position;
    while (candidate > 0) {
        if (dfuds_bit_at(bits, candidate)) balance -= 1;
        else balance += 1;
        if (balance == 0) return candidate;
        candidate -= 1;
    }
    0
}

fn usz dfuds_previous_zero(ulong bits, usz position) {
    usz candidate = position;
    while (candidate > 1) {
        if (!dfuds_bit_at(bits, candidate - 1)) return candidate - 1;
        candidate -= 1;
    }
    0
}

fn void dfuds_write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long dfuds_ordered_tree_navigation_impl(long* input, usz length,
    char* output, usz capacity) {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || q_value < 0 || q_value > (long)MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length != 2 + (n - 1) + 3 * q) return -1;

    usz[MAX_N] parent = zeroed;
    for (usz vertex = 1; vertex < n; vertex += 1) {
        long value = input[1 + vertex];
        if (value < 0 || (ulong)value >= vertex) return -1;
        parent[vertex] = (usz)value;
    }
    usz query_base = n + 1;
    for (usz index = 0; index < q; index += 1) {
        usz offset = query_base + 3 * index;
        long opcode = input[offset], node = input[offset + 1], argument = input[offset + 2];
        if (node < 0 || node >= n_value) return -1;
        if (opcode == 0 || opcode == 2) {
            if (argument != 0) return -1;
        } else if (opcode == 1) {
            if (argument < 0 || argument > n_value) return -1;
        } else return -1;
    }

    usz[MAX_N] order = zeroed, stack_node = zeroed, next_child = zeroed;
    usz order_count = 1, depth = 1;
    next_child[0] = 1;
    while (depth > 0) {
        usz frame = depth - 1;
        usz node = stack_node[frame];
        usz child = next_child[frame];
        while (child < n && parent[child] != node) child += 1;
        if (child < n) {
            next_child[frame] = child + 1;
            order[order_count] = child;
            order_count += 1;
            stack_node[depth] = child;
            next_child[depth] = 1;
            depth += 1;
        } else depth -= 1;
    }
    if (order_count != n) return -1;

    usz[MAX_N] descriptor = zeroed;
    int[MAX_BITS + 2] position_to_node;
    for (usz position = 0; position < MAX_BITS + 2; position += 1) position_to_node[position] = -1;
    ulong packed = 1;
    usz bit_length = 1;
    for (usz node = 0; node < n; node += 1) {
        usz degree = 0;
        for (usz child = 1; child < n; child += 1)
            if (parent[child] == order[node]) degree += 1;
        descriptor[node] = bit_length + 1;
        position_to_node[descriptor[node]] = (int)node;
        for (usz child = 0; child < degree; child += 1) {
            packed |= ((ulong)1) << bit_length;
            bit_length += 1;
        }
        bit_length += 1;
    }
    if (bit_length != 2 * n) return -1;

    long[MAX_OUTPUT_WORDS] words = zeroed;
    words[0] = n_value;
    words[1] = (long)bit_length;
    words[2] = (long)packed;
    words[3] = q_value;
    for (usz index = 0; index < q; index += 1) {
        usz offset = query_base + 3 * index;
        long opcode = input[offset];
        usz node = (usz)input[offset + 1];
        long argument = input[offset + 2];
        usz start = descriptor[node], degree = 0;
        while (start + degree <= bit_length && dfuds_bit_at(packed, start + degree)) degree += 1;
        long answer = -1;
        if (opcode == 0) answer = (long)degree;
        else if (opcode == 1) {
            if ((ulong)argument < degree) {
                usz target = start + degree - ((usz)argument + 1);
                usz child_start = dfuds_find_close(packed, bit_length, target) + 1;
                if (child_start > MAX_BITS + 1 || position_to_node[child_start] < 0) return -1;
                answer = position_to_node[child_start];
            }
        } else if (node != 0) {
            usz matched_open = dfuds_find_open(packed, start - 1);
            usz parent_position = dfuds_previous_zero(packed, matched_open) + 1;
            if (parent_position == 1) answer = 0;
            else if (parent_position <= MAX_BITS + 1 && position_to_node[parent_position] >= 0)
                answer = position_to_node[parent_position];
            else return -1;
        }
        words[4 + index] = answer;
    }

    usz output_words = 4 + q, required = 8 * output_words;
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index < output_words; index += 1)
        dfuds_write_i64_le(output, 8 * index, words[index]);
    return (long)required;
}

export fn long dfuds_ordered_tree_navigation(long* input, usz length,
    char* output, usz capacity) @export("dfuds_ordered_tree_navigation") {
    dfuds_ordered_tree_navigation_impl(input, length, output, capacity)
}

module bp_ordered_tree_navigation;

const usz MAX_N = 31;
const usz MAX_Q = 32;
const usz MAX_INPUT = 129;
const usz MAX_BITS = 2 * MAX_N;
const usz MAX_OUTPUT_WORDS = 4 + MAX_Q;

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long bp_ordered_tree_navigation(long* input, usz length, char* output,
    usz capacity) @export("bp_ordered_tree_navigation") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || q_value < 0 || q_value > (long)MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value, bit_length = 2 * n;
    if (length != 2 + n - 1 + 3 * q) return -1;
    usz[MAX_N] parent = zeroed;
    for (usz vertex = 1; vertex < n; vertex += 1) {
        long value = input[1 + vertex];
        if (value < 0 || (ulong)value >= vertex) return -1;
        parent[vertex] = (usz)value;
    }
    usz query_base = n + 1;
    for (usz index = 0; index < q; index += 1) {
        usz offset = query_base + 3 * index;
        long opcode = input[offset], first = input[offset + 1], second = input[offset + 2];
        if (opcode == 0 || opcode == 1) {
            if (first < 0 || (ulong)first > bit_length || second < -(long)bit_length || second > (long)bit_length) return -1;
        } else if (opcode == 2) {
            if (first < 0 || second < first || (ulong)second >= bit_length) return -1;
        } else if (opcode >= 3 && opcode <= 5) {
            if (first < 0 || (ulong)first >= bit_length || second != 0) return -1;
        } else return -1;
    }

    u8[MAX_BITS] bits = zeroed;
    usz[MAX_N + 1] stack_node = zeroed, next_child = zeroed;
    usz bit_count = 0, depth = 1;
    bits[bit_count] = 1; bit_count += 1; next_child[0] = 1;
    while (depth > 0) {
        usz frame = depth - 1, node = stack_node[frame], child = next_child[frame];
        while (child < n && parent[child] != node) child += 1;
        if (child < n) {
            next_child[frame] = child + 1;
            bits[bit_count] = 1; bit_count += 1;
            stack_node[depth] = child; next_child[depth] = 1; depth += 1;
        } else {
            bits[bit_count] = 0; bit_count += 1; depth -= 1;
        }
    }
    if (bit_count != bit_length) return -1;
    long[MAX_BITS + 1] excess = zeroed;
    ulong packed = 0;
    for (usz position = 0; position < bit_length; position += 1) {
        if (bits[position] != 0) {
            packed |= ((ulong)1) << position;
            excess[position + 1] = excess[position] + 1;
        } else {
            excess[position + 1] = excess[position] - 1;
        }
    }
    for (usz index = 0; index < q; index += 1) {
        usz offset = query_base + 3 * index;
        long opcode = input[offset], first = input[offset + 1];
        if ((opcode == 3 && bits[(usz)first] == 0) || (opcode == 4 && bits[(usz)first] != 0) ||
            (opcode == 5 && bits[(usz)first] == 0)) return -1;
    }
    long[MAX_OUTPUT_WORDS] words = zeroed;
    words[0] = n_value; words[1] = (long)bit_length; words[2] = (long)packed; words[3] = q_value;
    for (usz index = 0; index < q; index += 1) {
        usz offset = query_base + 3 * index, first = (usz)input[offset + 1];
        long opcode = input[offset], second = input[offset + 2], answer = -1;
        if (opcode == 0 || opcode == 1) {
            long target = excess[first] + second;
            if (opcode == 0) {
                answer = (long)bit_length + 1;
                for (usz position = first + 1; position <= bit_length; position += 1)
                    if (excess[position] == target) { answer = (long)position; break; }
            } else {
                answer = 0;
                usz position = first;
                while (position > 0) { position -= 1; if (excess[position] == target) { answer = (long)position; break; } }
            }
        } else if (opcode == 2) {
            usz best = first, right = (usz)second;
            for (usz position = first + 1; position <= right; position += 1)
                if (excess[position + 1] < excess[best + 1]) best = position;
            answer = (long)best;
        } else if (opcode == 3) {
            long target = excess[first + 1] - 1;
            for (usz position = first + 2; position <= bit_length; position += 1)
                if (excess[position] == target) { answer = (long)(position - 1); break; }
        } else if (opcode == 4) {
            long target = excess[first + 1]; usz position = first + 1;
            while (position > 0) { position -= 1; if (excess[position] == target) { answer = (long)position; break; } }
        } else if (first == 0) answer = -1;
        else {
            long target = excess[first + 1] - 2; usz position = first + 1;
            while (position > 0) { position -= 1; if (excess[position] == target) { answer = (long)position; break; } }
        }
        words[4 + index] = answer;
    }
    usz required = 8 * (4 + q);
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index < 4 + q; index += 1) write_i64_le(output, 8 * index, words[index]);
    return (long)required;
}

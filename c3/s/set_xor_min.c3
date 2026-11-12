module set_xor_min;

const usz MAX_Q = 64;
const usz MAX_BITS = 30;
const usz MAX_NODES = 1 + MAX_BITS * MAX_Q;
const usz MAX_INPUT_VALUES = 1 + 2 * MAX_Q;

fn int find_or_create_child(int[MAX_NODES][2]* children, int* node_count,
    int node, int direction) {
    int child = children[node][direction];
    if (child < 0) {
        child = *node_count;
        *node_count += 1;
        children[child][0] = -1;
        children[child][1] = -1;
        children[node][direction] = child;
    }
    return child;
}

fn void insert_value(int[MAX_NODES][2]* children, int[MAX_NODES]* count,
    int* node_count, ulong value) {
    int[MAX_BITS + 1] path;
    int node = 0;
    path[0] = 0;
    for (int depth = 0; depth < (int)MAX_BITS; depth += 1) {
        int bit = (int)MAX_BITS - 1 - depth;
        int direction = (int)((value >> (usz)bit) & 1);
        node = find_or_create_child(children, node_count, node, direction);
        path[depth + 1] = node;
    }
    if (count[node] != 0) return;
    for (int depth = 0; depth <= (int)MAX_BITS; depth += 1) count[path[depth]] += 1;
}

fn void remove_value(int[MAX_NODES][2]* children, int[MAX_NODES]* count, ulong value) {
    int[MAX_BITS + 1] path;
    int node = 0;
    path[0] = 0;
    for (int depth = 0; depth < (int)MAX_BITS; depth += 1) {
        int bit = (int)MAX_BITS - 1 - depth;
        int direction = (int)((value >> (usz)bit) & 1);
        node = children[node][direction];
        if (node < 0) return;
        path[depth + 1] = node;
    }
    if (count[node] == 0) return;
    for (int depth = 0; depth <= (int)MAX_BITS; depth += 1) count[path[depth]] -= 1;
}

fn ulong minimum_xor(int[MAX_NODES][2]* children, int[MAX_NODES]* count, ulong value) {
    int node = 0;
    ulong result = 0;
    for (int bit = (int)MAX_BITS - 1; bit >= 0; bit -= 1) {
        int preferred = (int)((value >> (usz)bit) & 1);
        int child = children[node][preferred];
        if (child >= 0 && count[child] > 0) {
            node = child;
        } else {
            result |= (ulong)1 << (usz)bit;
            node = children[node][preferred ^ 1];
        }
    }
    return result;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long set_xor_min(long* input, usz length, char* output, usz capacity)
    @export("set_xor_min") {
    if (input == null || length < 3 || length > MAX_INPUT_VALUES) return -1;
    long q_value = input[0];
    if (q_value < 1 || q_value > (long)MAX_Q) return -1;
    usz q = (usz)q_value;
    if (length != 1 + 2 * q) return -1;
    for (usz operation = 0; operation < q; operation += 1) {
        usz offset = 1 + 2 * operation;
        if (input[offset] < 0 || input[offset] > 2 ||
            input[offset + 1] < 0 || input[offset + 1] >= 1073741824) return -1;
    }

    int[MAX_NODES][2] children;
    int[MAX_NODES] count = zeroed;
    for (usz node = 0; node < MAX_NODES; node += 1) {
        children[node][0] = -1;
        children[node][1] = -1;
    }
    int node_count = 1;
    long[MAX_Q] answers = zeroed;
    usz answer_count = 0;
    for (usz operation = 0; operation < q; operation += 1) {
        usz offset = 1 + 2 * operation;
        long kind = input[offset];
        ulong value = (ulong)input[offset + 1];
        if (kind == 0) {
            insert_value(&children, &count, &node_count, value);
        } else if (kind == 1) {
            remove_value(&children, &count, value);
        } else {
            if (count[0] == 0) return -1;
            answers[answer_count] = (long)minimum_xor(&children, &count, value);
            answer_count += 1;
        }
    }

    usz required = 8 * answer_count;
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index < answer_count; index += 1)
        store_i64_le(output, 8 * index, answers[index]);
    return (long)required;
}

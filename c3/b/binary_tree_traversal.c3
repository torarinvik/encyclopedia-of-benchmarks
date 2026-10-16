module binary_tree_traversal;

const usz MAX_NODES = 64;
const usz MAX_INPUT_LENGTH = 3 + 3 * MAX_NODES;

fn void walk(long order, long* values, long* left, long* right, usz node, long* output, usz* used) {
    if (order == 0) { output[*used] = values[node]; *used += 1; }
    if (left[node] >= 0) walk(order, values, left, right, (usz)left[node], output, used);
    if (order == 1) { output[*used] = values[node]; *used += 1; }
    if (right[node] >= 0) walk(order, values, left, right, (usz)right[node], output, used);
    if (order == 2) { output[*used] = values[node]; *used += 1; }
}

fn void breadth_first(long order, long* values, long* left, long* right, usz root, long* output, usz* used) {
    usz[MAX_NODES] queue;
    usz head = 0;
    usz tail = 1;
    queue[0] = root;
    while (head < tail) {
        usz node = queue[head]; head += 1;
        output[*used] = values[node]; *used += 1;
        long first = order == 3 ? left[node] : right[node];
        long second = order == 3 ? right[node] : left[node];
        if (first >= 0) { queue[tail] = (usz)first; tail += 1; }
        if (second >= 0) { queue[tail] = (usz)second; tail += 1; }
    }
}

fn void breadth_first_zigzag(long* values, long* left, long* right, usz root, long* output, usz* used) {
    usz[MAX_NODES] queue;
    usz head = 0;
    usz tail = 1;
    usz level = 0;
    queue[0] = root;
    while (head < tail) {
        usz level_end = tail;
        usz start = *used;
        while (head < level_end) {
            usz node = queue[head]; head += 1;
            output[*used] = values[node]; *used += 1;
            if (left[node] >= 0) { queue[tail] = (usz)left[node]; tail += 1; }
            if (right[node] >= 0) { queue[tail] = (usz)right[node]; tail += 1; }
        }
        if (level % 2 == 1) {
            usz lo = start;
            usz hi = *used;
            while (lo < hi) {
                hi -= 1;
                if (lo >= hi) break;
                long value = output[lo]; output[lo] = output[hi]; output[hi] = value;
                lo += 1;
            }
        }
        level += 1;
    }
}

fn usz mark_reachable(long* left, long* right, usz root, bool* seen) {
    usz[MAX_NODES] stack;
    usz top = 1;
    usz count = 0;
    stack[0] = root;
    while (top > 0) {
        top -= 1;
        usz node = stack[top];
        if (seen[node]) continue;
        seen[node] = true;
        count += 1;
        if (right[node] >= 0) { stack[top] = (usz)right[node]; top += 1; }
        if (left[node] >= 0) { stack[top] = (usz)left[node]; top += 1; }
    }
    return count;
}

fn void put_i64(char* output, usz index, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[index * 8 + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long binary_tree_traversal(long* input, usz length, char* output, usz capacity)
    @export("binary_tree_traversal") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long order = input[0];
    long count_value = input[1];
    long root_value = input[2];
    if (order < 0 || order > 6 || count_value < 0 || count_value > (long)MAX_NODES) return -1;
    usz n = (usz)count_value;
    if (length != 3 + 3 * n || (n == 0 && root_value != -1) || (n > 0 && (root_value < 0 || root_value >= (long)n))) return -1;

    long[MAX_NODES] values;
    long[MAX_NODES] left;
    long[MAX_NODES] right;
    long[MAX_NODES] parents;
    for (usz i = 0; i < MAX_NODES; i++) { values[i] = 0; left[i] = -1; right[i] = -1; parents[i] = 0; }
    for (usz i = 0; i < n; i++) {
        values[i] = input[3 + 3 * i];
        left[i] = input[4 + 3 * i];
        right[i] = input[5 + 3 * i];
        if (left[i] < -1 || left[i] >= (long)n || right[i] < -1 || right[i] >= (long)n || left[i] == (long)i || right[i] == (long)i) return -1;
        if (left[i] >= 0) { usz child = (usz)left[i]; parents[child] += 1; if (parents[child] > 1) return -1; }
        if (right[i] >= 0) { usz child = (usz)right[i]; parents[child] += 1; if (parents[child] > 1) return -1; }
    }
    long[MAX_NODES] result;
    usz used = 0;
    if (n > 0) {
        usz root = (usz)root_value;
        for (usz i = 0; i < n; i++) {
            long expected = 1;
            if (i == root) expected = 0;
            if (parents[i] != expected) return -1;
        }
        bool[MAX_NODES] seen;
        for (usz i = 0; i < MAX_NODES; i++) seen[i] = false;
        if (mark_reachable(&left[0], &right[0], root, &seen[0]) != n) return -1;
        if (order <= 2) { walk(order, &values[0], &left[0], &right[0], root, &result[0], &used); }
        else if (order == 5) { walk(1, &values[0], &right[0], &left[0], root, &result[0], &used); }
        else if (order == 6) { breadth_first_zigzag(&values[0], &left[0], &right[0], root, &result[0], &used); }
        else { breadth_first(order, &values[0], &left[0], &right[0], root, &result[0], &used); }
    }
    usz required = used * 8;
    if (output == null || capacity < required) return -2;
    for (usz i = 0; i < used; i++) put_i64(output, i, result[i]);
    return (long)required;
}

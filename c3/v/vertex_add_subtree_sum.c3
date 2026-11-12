module vertex_add_subtree_sum;

const int MAX_N = 128;
const int MAX_Q = 256;
const usz MAX_INPUT_VALUES = 2 * (usz)MAX_N + 1 + 3 * (usz)MAX_Q;
const long MAX_VALUE = 1000000;

fn void fenwick_add(long* tree, int n, int position, long delta) {
    int index = position + 1;
    while (index <= n) {
        tree[index] += delta;
        index += index & -index;
    }
}

fn long fenwick_prefix(long* tree, int count) {
    long total = 0;
    int index = count;
    while (index > 0) {
        total += tree[index];
        index -= index & -index;
    }
    return total;
}

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long vertex_add_subtree_sum(long* input, usz length, char* output, usz capacity)
    @export("vertex_add_subtree_sum") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    long nv = input[0], qv = input[1];
    if (nv < 1 || nv > MAX_N || qv < 0 || qv > MAX_Q) return -1;
    int n = (int)nv, q = (int)qv;
    if (length != 2 * (usz)n + 1 + 3 * (usz)q) return -1;

    long[MAX_N] values, first_child, next_sibling;
    for (int vertex = 0; vertex < MAX_N; vertex++) {
        values[vertex] = 0;
        first_child[vertex] = -1;
        next_sibling[vertex] = -1;
    }
    for (int vertex = 0; vertex < n; vertex++) {
        values[vertex] = input[2 + (usz)vertex];
        if (values[vertex] < 0 || values[vertex] > MAX_VALUE) return -1;
    }
    usz parent_start = 2 + (usz)n;
    for (int vertex = 1; vertex < n; vertex++) {
        long parent_value = input[parent_start + (usz)(vertex - 1)];
        if (parent_value < 0 || parent_value >= (long)vertex) return -1;
        int parent = (int)parent_value;
        next_sibling[vertex] = first_child[parent];
        first_child[parent] = vertex;
    }

    int[MAX_N] tin, tout, stack_node;
    long[MAX_N] stack_next_child;
    int timer = 0, top = 1;
    stack_node[0] = 0;
    stack_next_child[0] = first_child[0];
    tin[0] = timer++;
    while (top > 0) {
        int frame = top - 1;
        long child_value = stack_next_child[frame];
        if (child_value < 0) {
            tout[stack_node[frame]] = timer;
            top--;
            continue;
        }
        int child = (int)child_value;
        stack_next_child[frame] = next_sibling[child];
        tin[child] = timer++;
        stack_node[top] = child;
        stack_next_child[top] = first_child[child];
        top++;
    }

    long[MAX_N + 1] fenwick;
    for (int index = 0; index <= MAX_N; index++) fenwick[index] = 0;
    for (int vertex = 0; vertex < n; vertex++) fenwick_add(&fenwick[0], n, tin[vertex], values[vertex]);

    long[MAX_Q] answers;
    int answer_count = 0;
    usz operation_start = parent_start + (usz)n - 1;
    for (int index = 0; index < q; index++) {
        usz offset = operation_start + 3 * (usz)index;
        long kind = input[offset], vertex_value = input[offset + 1], operand = input[offset + 2];
        if (kind == 0) {
            if (vertex_value < 0 || vertex_value >= nv || operand < 0 || operand > MAX_VALUE) return -1;
            int vertex = (int)vertex_value;
            values[vertex] += operand;
            fenwick_add(&fenwick[0], n, tin[vertex], operand);
        } else if (kind == 1) {
            if (vertex_value < 0 || vertex_value >= nv || operand != 0) return -1;
            int vertex = (int)vertex_value;
            answers[answer_count++] = fenwick_prefix(&fenwick[0], tout[vertex]) -
                fenwick_prefix(&fenwick[0], tin[vertex]);
        } else return -1;
    }

    usz output_bytes = 8 * (usz)answer_count;
    if (output_bytes > 0 && (output == null || capacity < output_bytes)) return -2;
    for (int index = 0; index < answer_count; index++) put_i64_le(output, 8 * (usz)index, answers[index]);
    return (long)output_bytes;
}

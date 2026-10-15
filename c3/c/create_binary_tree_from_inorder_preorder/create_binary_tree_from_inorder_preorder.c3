module create_binary_tree_from_inorder_preorder;

const usz MAX_NODES = 63;
const usz MAX_OUTPUT = 6 * MAX_NODES + 1;

fn long create_binary_tree_from_inorder_preorder(long* values, usz length, char* output, usz output_capacity)
    @export("create_binary_tree_from_inorder_preorder") {
    if (values == null || length < 1 || values[0] < 0 || values[0] > (long)MAX_NODES) return -1;
    usz count = (usz)values[0];
    if (length != 1 + 2 * count) return -1;
    for (usz i = 0; i < count; i++) {
        long pre = values[1 + i], in = values[1 + count + i];
        if (pre < -2147483648 || pre > 2147483647 || in < -2147483648 || in > 2147483647) return -1;
        for (usz j = 0; j < i; j++)
            if (pre == values[1 + j] || in == values[1 + count + j]) return -1;
        usz matches = 0;
        for (usz j = 0; j < count; j++) if (pre == values[1 + count + j]) matches++;
        if (matches != 1) return -1;
    }
    long[MAX_NODES] left_child, right_child;
    for (usz i = 0; i < count; i++) { left_child[i] = -1; right_child[i] = -1; }
    long[MAX_NODES] task_pre, task_in, task_size;
    usz task_count = 0;
    if (count > 0) { task_pre[0] = 0; task_in[0] = 0; task_size[0] = (long)count; task_count++; }
    while (task_count > 0) {
        task_count--;
        long pre_start = task_pre[task_count], in_start = task_in[task_count], size = task_size[task_count];
        if (size <= 0 || pre_start + size > (long)count || in_start + size > (long)count) return -1;
        long root_pos = -1;
        for (long i = in_start; i < in_start + size; i++)
            if (values[1 + (usz)i] == values[1 + count + (usz)pre_start]) { root_pos = i; break; }
        if (root_pos < 0) return -1;
        long left_size = root_pos - in_start, right_size = size - left_size - 1;
        if (left_size > 0) left_child[(usz)pre_start] = pre_start + 1;
        if (right_size > 0) right_child[(usz)pre_start] = pre_start + left_size + 1;
        if (right_size > 0) { task_pre[task_count] = pre_start + left_size + 1; task_in[task_count] = root_pos + 1; task_size[task_count++] = right_size; }
        if (left_size > 0) { task_pre[task_count] = pre_start + 1; task_in[task_count] = in_start; task_size[task_count++] = left_size; }
    }
    usz required = 6 * count + 1;
    if (output == null || output_capacity < required) return -2;
    char[MAX_OUTPUT] encoded;
    long[2 * MAX_NODES + 1] pending;
    usz top = 1, written = 0;
    pending[0] = count == 0 ? -1 : 0;
    while (top > 0) {
        long node = pending[--top];
        if (node < 0) encoded[written++] = 0;
        else {
            ulong value = (ulong)values[1 + (usz)node];
            encoded[written++] = 1;
            for (usz byte = 0; byte < 4; byte++) encoded[written++] = (char)((value >> (8 * byte)) & 255);
            pending[top++] = right_child[(usz)node];
            pending[top++] = left_child[(usz)node];
        }
    }
    for (usz i = 0; i < written; i++) output[i] = encoded[i];
    return (long)count;
}

module tree_path_value;

fn long tree_path_value(long* packed, usz length) @export("tree_path_value") {
    if (packed == null || length < 1 || length > 121) return -1;
    if (packed[0] < 1 || packed[0] > 14) return -1;
    long depth = packed[0];
    usz count = length - 1;
    if (count == 0) return 0;

    long values[120];
    int left[120], right[120];
    for (usz i = 0; i < count; i++) {
        values[i] = packed[i + 1];
        left[i] = -1; right[i] = -1;
        if ((i == 0 && (values[i] < -1000 || values[i] > 1000))
                || (i > 0 && (values[i] < 1 || values[i] > 1000))) return -1;
    }
    usz row_start = 0, width = 1;
    while (row_start < count) {
        for (usz column = 0; column < width && row_start + column < count; column++) {
            usz parent = row_start + column;
            usz left_index = row_start + width + column;
            usz right_index = left_index + 1;
            if (left_index < count) left[parent] = (int)left_index;
            if (right_index < count) right[parent] = (int)right_index;
        }
        row_start += width;
        width++;
    }

    int pivot = 0;
    long maximum = values[0];
    while (left[pivot] >= 0) {
        int stack_node[16], stack_steps[16];
        long stack_sum[16];
        usz top = 0;
        stack_node[top] = pivot; stack_steps[top] = (int)depth;
        stack_sum[top] = maximum; top++;
        while (top > 0) {
            top--;
            int node = stack_node[top], steps = stack_steps[top];
            long sum = stack_sum[top];
            if (steps == 0) {
                if (sum > maximum) { maximum = sum; pivot = node; }
                continue;
            }
            if (right[node] >= 0) {
                stack_node[top] = right[node]; stack_steps[top] = steps - 1;
                stack_sum[top] = sum + values[right[node]]; top++;
            }
            if (left[node] >= 0) {
                stack_node[top] = left[node]; stack_steps[top] = steps - 1;
                stack_sum[top] = sum + values[left[node]]; top++;
            } else if (sum > maximum) {
                maximum = sum; pivot = node;
            }
        }
    }
    return maximum;
}

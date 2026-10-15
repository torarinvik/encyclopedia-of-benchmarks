module trim_bst;

const usz MAX_NODE_COUNT = 100;
const long MAX_VALUE = 10000;

fn bool valid_bst(long* nodes, usz node_count, long root_index) {
    usz[MAX_NODE_COUNT] parents;
    for (usz index = 0; index < MAX_NODE_COUNT; index++) parents[index] = 0;
    for (usz index = 0; index < node_count; index++) {
        long value = nodes[3 * index];
        long left = nodes[3 * index + 1];
        long right = nodes[3 * index + 2];
        if (value < 1 || value > MAX_VALUE || left < -1 || right < -1 ||
            (left >= 0 && (usz)left >= node_count) || (right >= 0 && (usz)right >= node_count)) return false;
        if (left >= 0) {
            parents[(usz)left]++;
            if (parents[(usz)left] > 1) return false;
        }
        if (right >= 0) {
            parents[(usz)right]++;
            if (parents[(usz)right] > 1) return false;
        }
    }
    if (parents[(usz)root_index] != 0) return false;
    for (usz index = 0; index < node_count; index++) {
        if ((long)index != root_index && parents[index] != 1) return false;
    }

    long[MAX_NODE_COUNT] stack_node;
    long[MAX_NODE_COUNT] stack_low;
    long[MAX_NODE_COUNT] stack_high;
    bool[MAX_NODE_COUNT] seen;
    for (usz index = 0; index < MAX_NODE_COUNT; index++) seen[index] = false;
    usz top = 1;
    usz visited = 0;
    stack_node[0] = root_index;
    stack_low[0] = 0;
    stack_high[0] = MAX_VALUE + 1;
    while (top > 0) {
        top--;
        usz index = (usz)stack_node[top];
        long lower = stack_low[top];
        long upper = stack_high[top];
        if (seen[index]) return false;
        seen[index] = true;
        visited++;
        long value = nodes[3 * index];
        if (value <= lower || value >= upper) return false;
        long left = nodes[3 * index + 1];
        long right = nodes[3 * index + 2];
        if (right >= 0) {
            stack_node[top] = right;
            stack_low[top] = value;
            stack_high[top] = upper;
            top++;
        }
        if (left >= 0) {
            stack_node[top] = left;
            stack_low[top] = lower;
            stack_high[top] = value;
            top++;
        }
    }
    return visited == node_count;
}

fn long trim_node(long* nodes, long node, long low, long high, long* output, usz* output_count) {
    if (node == -1) return -1;
    usz index = (usz)node;
    long value = nodes[3 * index];
    long left = nodes[3 * index + 1];
    long right = nodes[3 * index + 2];
    if (value < low) return trim_node(nodes, right, low, high, output, output_count);
    if (value > high) return trim_node(nodes, left, low, high, output, output_count);
    usz trimmed_index = output_count[0];
    output_count[0]++;
    usz offset = 1 + 3 * trimmed_index;
    output[offset] = value;
    output[offset + 1] = -1;
    output[offset + 2] = -1;
    output[offset + 1] = trim_node(nodes, left, low, high, output, output_count);
    output[offset + 2] = trim_node(nodes, right, low, high, output, output_count);
    return (long)trimmed_index;
}

fn long trim_bst(long* nodes, usz node_count, long root_index, long low, long high,
                 long* output, usz output_capacity) @export("trim_bst") {
    if (node_count > MAX_NODE_COUNT || low < 1 || high > MAX_VALUE || low > high) return -1;
    if (node_count == 0) {
        if (root_index != -1) return -1;
        if (output == null || output_capacity < 1) return -2;
        output[0] = -1;
        return 1;
    }
    if (nodes == null || root_index < 0 || (usz)root_index >= node_count ||
        !valid_bst(nodes, node_count, root_index)) return -1;
    if (output == null || output_capacity < 1 + 3 * node_count) return -2;
    usz output_count = 0;
    output[0] = trim_node(nodes, root_index, low, high, output, &output_count);
    return (long)(1 + 3 * output_count);
}

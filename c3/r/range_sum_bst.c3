module range_sum_bst;

const usz MAX_NODE_COUNT = 1023;
const long MAX_VALUE = 100000;

fn long range_sum_bst(long* nodes, usz node_count, long root_index, long low, long high)
        @export("range_sum_bst") {
    if (node_count > MAX_NODE_COUNT || low < 1 || high > MAX_VALUE || low > high) return -1;
    if (node_count == 0) return root_index == -1 ? 0 : -1;
    if (nodes == null || root_index < 0 || (usz)root_index >= node_count) return -1;

    long[MAX_NODE_COUNT] parents;
    long[MAX_NODE_COUNT] seen;
    long[MAX_NODE_COUNT] stack_node;
    long[MAX_NODE_COUNT] stack_low;
    long[MAX_NODE_COUNT] stack_high;
    for (usz index = 0; index < MAX_NODE_COUNT; index++) {
        parents[index] = 0;
        seen[index] = 0;
    }
    for (usz index = 0; index < node_count; index++) {
        long value = nodes[3 * index];
        long left = nodes[3 * index + 1];
        long right = nodes[3 * index + 2];
        if (value < 1 || value > MAX_VALUE || left < -1 || right < -1 ||
            (left >= 0 && (usz)left >= node_count) ||
            (right >= 0 && (usz)right >= node_count)) return -1;
        if (left >= 0) {
            parents[(usz)left] += 1;
            if (parents[(usz)left] > 1) return -1;
        }
        if (right >= 0) {
            parents[(usz)right] += 1;
            if (parents[(usz)right] > 1) return -1;
        }
    }
    if (parents[(usz)root_index] != 0) return -1;
    for (usz index = 0; index < node_count; index++) {
        if (index != (usz)root_index && parents[index] != 1) return -1;
    }

    usz top = 1;
    usz visited = 0;
    stack_node[0] = root_index;
    stack_low[0] = 0;
    stack_high[0] = MAX_VALUE + 1;
    long total = 0;
    while (top > 0) {
        top -= 1;
        usz index = (usz)stack_node[top];
        long lower = stack_low[top];
        long upper = stack_high[top];
        if (seen[index] != 0) return -1;
        seen[index] = 1;
        visited += 1;
        long value = nodes[3 * index];
        long left = nodes[3 * index + 1];
        long right = nodes[3 * index + 2];
        if (value <= lower || value >= upper) return -1;
        if (low <= value && value <= high) total += value;
        if (right >= 0) {
            stack_node[top] = right;
            stack_low[top] = value;
            stack_high[top] = upper;
            top += 1;
        }
        if (left >= 0) {
            stack_node[top] = left;
            stack_low[top] = lower;
            stack_high[top] = value;
            top += 1;
        }
    }
    return visited == node_count ? total : -1;
}

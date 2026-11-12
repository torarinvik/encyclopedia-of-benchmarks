module lowest_common_ancestor_farach_colton_bender;

const usz MAX_NODES = 256;
const usz MAX_QUERIES = 1024;
const usz MAX_ARCS = 510;
const usz MAX_EULER = 2 * MAX_NODES - 1;
const usz MAX_BLOCKS = 128;
const usz MAX_LEVELS = 8;
const usz MAX_MICRO = 4;

fn int shallower(int a, int b, int* depth) {
    if (depth[a] != depth[b]) return depth[a] < depth[b] ? a : b;
    return a < b ? a : b;
}

fn int range_minimum(int first, int last, usz euler_count, usz block_size,
    int* depth, int* pattern, int* micro, int* macro, int* logs) {
    usz block_a = (usz)first / block_size;
    usz block_b = (usz)last / block_size;
    usz offset_a = (usz)first % block_size;
    usz offset_b = (usz)last % block_size;
    if (block_a == block_b) return (int)(block_a * block_size + (usz)micro[(pattern[block_a] * 4 + offset_a) * 4 + offset_b]);
    usz base_a = block_a * block_size;
    usz base_b = block_b * block_size;
    usz len_a = euler_count - base_a < block_size ? euler_count - base_a : block_size;
    int best = (int)(base_a + (usz)micro[(pattern[block_a] * 4 + offset_a) * 4 + len_a - 1]);
    best = shallower(best, (int)(base_b + (usz)micro[(pattern[block_b] * 4) * 4 + offset_b]), depth);
    if (block_b > block_a + 1) {
        usz lo = block_a + 1;
        usz hi = block_b - 1;
        usz count = hi - lo + 1;
        usz level = (usz)logs[count];
        usz span = (usz)1 << level;
        best = shallower(best, macro[level * MAX_BLOCKS + lo], depth);
        best = shallower(best, macro[level * MAX_BLOCKS + hi - span + 1], depth);
    }
    return best;
}

fn long lowest_common_ancestor_farach_colton_bender(long* input, usz length,
    char* output, usz output_capacity) @export("lowest_common_ancestor_farach_colton_bender") {
    if (input == null || length < 4 || input[0] < 1 || input[0] > (long)MAX_NODES) return -1;
    usz node_count = (usz)input[0];
    if (input[1] < 0 || input[1] >= (long)node_count || input[2] != (long)(node_count - 1) ||
        input[3] < 0 || input[3] > (long)MAX_QUERIES) return -1;
    usz edge_count = (usz)input[2];
    usz query_count = (usz)input[3];
    usz query_offset = 4 + 2 * edge_count;
    if (length != query_offset + 2 * query_count) return -1;
    usz root = (usz)input[1];

    int[MAX_NODES] head;
    int[MAX_ARCS] arc_to, arc_next;
    int[MAX_NODES] parent, tree_depth, first;
    int[MAX_EULER] euler, euler_depth;
    int[MAX_NODES] stack_node, stack_arc;
    for (usz node = 0; node < node_count; node++) { head[node] = -1; parent[node] = -2; }
    usz arcs = 0;
    for (usz edge = 0; edge < edge_count; edge++) {
        long u = input[4 + 2 * edge];
        long v = input[5 + 2 * edge];
        if (u < 0 || u >= (long)node_count || v < 0 || v >= (long)node_count || u == v) return -1;
        usz a = (usz)u, b = (usz)v;
        arc_to[arcs] = (int)b; arc_next[arcs] = head[a]; head[a] = (int)arcs; arcs++;
        arc_to[arcs] = (int)a; arc_next[arcs] = head[b]; head[b] = (int)arcs; arcs++;
    }
    for (usz query = 0; query < query_count; query++) {
        for (usz side = 0; side < 2; side++) {
            long node = input[query_offset + 2 * query + side];
            if (node < 0 || node >= (long)node_count) return -1;
        }
    }

    usz euler_count = 1, top = 1, reached = 1;
    parent[root] = -1; tree_depth[root] = 0; first[root] = 0;
    euler[0] = (int)root; euler_depth[0] = 0;
    stack_node[0] = (int)root; stack_arc[0] = head[root];
    while (top > 0) {
        usz slot = top - 1;
        usz node = (usz)stack_node[slot];
        int arc = stack_arc[slot];
        if (arc < 0) {
            top--;
            if (top > 0) {
                usz up = (usz)stack_node[top - 1];
                euler[euler_count] = (int)up;
                euler_depth[euler_count] = tree_depth[up];
                euler_count++;
            }
            continue;
        }
        stack_arc[slot] = arc_next[(usz)arc];
        usz neighbor = (usz)arc_to[(usz)arc];
        if ((int)neighbor == parent[node]) continue;
        if (parent[neighbor] != -2) return -1;
        parent[neighbor] = (int)node;
        tree_depth[neighbor] = tree_depth[node] + 1;
        first[neighbor] = (int)euler_count;
        euler[euler_count] = (int)neighbor;
        euler_depth[euler_count] = tree_depth[neighbor];
        euler_count++;
        reached++;
        stack_node[top] = (int)neighbor; stack_arc[top] = head[neighbor]; top++;
    }
    if (reached != node_count) return -1;
    if (output_capacity < query_count || (query_count != 0 && output == null)) return -2;

    usz logarithm = 0;
    for (usz value = euler_count; value > 1; value = value / 2) logarithm++;
    usz block_size = logarithm / 2;
    if (block_size < 1) block_size = 1;
    usz block_count = (euler_count + block_size - 1) / block_size;
    int[8 * 4 * 4] micro;
    int[MAX_BLOCKS] pattern;
    int[MAX_BLOCKS + 1] logs;
    int[MAX_LEVELS * MAX_BLOCKS] macro;
    for (usz shape = 0; shape < ((usz)1 << (block_size - 1)); shape++) {
        int[4] relative;
        relative[0] = 0;
        for (usz step = 0; step + 1 < block_size; step++)
            relative[step + 1] = relative[step] + (((shape >> step) & 1) != 0 ? 1 : -1);
        for (usz left = 0; left < block_size; left++) {
            for (usz right = left; right < block_size; right++) {
                usz best = left;
                for (usz at = left + 1; at <= right; at++)
                    if (relative[at] < relative[best]) best = at;
                micro[(shape * 4 + left) * 4 + right] = (int)best;
            }
        }
    }
    for (usz block = 0; block < block_count; block++) {
        usz base = block * block_size;
        usz end = euler_count - base < block_size ? euler_count : base + block_size;
        int best = (int)base;
        pattern[block] = 0;
        for (usz at = base; at + 1 < end; at++) {
            if (euler_depth[at + 1] > euler_depth[at]) pattern[block] |= 1 << (at - base);
            best = shallower(best, (int)(at + 1), &euler_depth[0]);
        }
        macro[block] = best;
    }
    logs[0] = 0; logs[1] = 0;
    for (usz count = 2; count <= block_count; count++) logs[count] = logs[count / 2] + 1;
    usz macro_levels = 1;
    while (((usz)1 << macro_levels) <= block_count && macro_levels < MAX_LEVELS) {
        usz half = (usz)1 << (macro_levels - 1);
        usz span = 2 * half;
        for (usz block = 0; block + span <= block_count; block++)
            macro[macro_levels * MAX_BLOCKS + block] = shallower(
                macro[(macro_levels - 1) * MAX_BLOCKS + block],
                macro[(macro_levels - 1) * MAX_BLOCKS + block + half], &euler_depth[0]);
        macro_levels++;
    }
    int[MAX_QUERIES] answers;
    for (usz query = 0; query < query_count; query++) {
        usz u = (usz)input[query_offset + 2 * query];
        usz v = (usz)input[query_offset + 2 * query + 1];
        usz left = (usz)first[u], right = (usz)first[v];
        if (left > right) { usz temp = left; left = right; right = temp; }
        int at = range_minimum((int)left, (int)right, euler_count, block_size,
            &euler_depth[0], &pattern[0], &micro[0], &macro[0], &logs[0]);
        answers[query] = euler[(usz)at];
    }
    for (usz query = 0; query < query_count; query++) output[query] = (char)answers[query];
    return (long)query_count;
}

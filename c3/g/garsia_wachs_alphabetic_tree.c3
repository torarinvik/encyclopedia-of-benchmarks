module garsia_wachs_alphabetic_tree;

const usz MAX_N = 64;
const usz MAX_INPUT = MAX_N + 2;
const long MAX_WEIGHT = 1000000;
const long GW_INFINITY = 4611686018427387904;

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long garsia_wachs_alphabetic_tree(long* input, usz length, char* output, usz capacity)
    @export("garsia_wachs_alphabetic_tree") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N || length != (usz)n_value + 1) return -1;
    usz n = (usz)n_value;
    long[2 * MAX_N - 1] node_weight;
    int[2 * MAX_N - 1] left, right;
    int[MAX_N] active;
    for (usz i = 0; i < 2 * n - 1; i++) { node_weight[i] = 0; left[i] = -1; right[i] = -1; }
    for (usz i = 0; i < n; i++) {
        if (input[i + 1] < 0 || input[i + 1] > MAX_WEIGHT) return -1;
        node_weight[i] = input[i + 1];
        active[i] = (int)i;
    }
    usz active_count = n, next_node = n;
    while (active_count > 1) {
        usz pair = 0;
        for (; pair + 1 < active_count; pair++) {
            long following = pair + 2 < active_count ? node_weight[active[pair + 2]] : GW_INFINITY;
            if (node_weight[active[pair]] <= following) break;
        }
        int first = active[pair], second = active[pair + 1];
        long combined = node_weight[first] + node_weight[second];
        node_weight[next_node] = combined;
        left[next_node] = first;
        right[next_node] = second;
        usz earlier = pair;
        while (earlier > 0 && node_weight[active[earlier - 1]] < combined) earlier--;
        usz insert_at = earlier;
        for (usz i = pair; i + 2 < active_count; i++) active[i] = active[i + 2];
        active_count -= 2;
        for (usz i = active_count; i > insert_at; i--) active[i] = active[i - 1];
        active[insert_at] = (int)next_node;
        active_count++;
        next_node++;
    }

    int[MAX_N] depths;
    for (usz i = 0; i < n; i++) depths[i] = 0;
    int[2 * MAX_N] stack_node, stack_depth;
    usz top = 1;
    stack_node[0] = active[0]; stack_depth[0] = 0;
    while (top > 0) {
        top--;
        int node = stack_node[top], depth = stack_depth[top];
        if ((usz)node < n) depths[node] = depth;
        else {
            stack_node[top] = right[node]; stack_depth[top] = depth + 1; top++;
            stack_node[top] = left[node]; stack_depth[top] = depth + 1; top++;
        }
    }

    int[2 * MAX_N - 1] ordered_left, ordered_right;
    int[2 * MAX_N] code_node, code_depth;
    for (usz i = 0; i < 2 * n - 1; i++) { ordered_left[i] = -1; ordered_right[i] = -1; }
    usz code_top = 0, next_ordered = n;
    for (usz leaf = 0; leaf < n; leaf++) {
        code_node[code_top] = (int)leaf;
        code_depth[code_top] = depths[leaf];
        code_top++;
        while (code_top >= 2 && code_depth[code_top - 1] == code_depth[code_top - 2]) {
            int level = code_depth[code_top - 1];
            if (level <= 0 || next_ordered >= 2 * n - 1) return -1;
            ordered_left[next_ordered] = code_node[code_top - 2];
            ordered_right[next_ordered] = code_node[code_top - 1];
            code_top -= 2;
            code_node[code_top] = (int)next_ordered;
            code_depth[code_top] = level - 1;
            code_top++;
            next_ordered++;
        }
    }
    if (code_top != 1 || code_depth[0] != 0 || next_ordered != 2 * n - 1) return -1;
    long cost = 0;
    for (usz i = 0; i < n; i++) cost += input[i + 1] * (long)depths[i];
    usz output_bytes = 8 * (n + 1);
    if (output == null || capacity < output_bytes) return -2;
    put_i64_le(output, 0, cost);
    for (usz i = 0; i < n; i++) put_i64_le(output, 8 * (i + 1), (long)depths[i]);
    return (long)output_bytes;
}

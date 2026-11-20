module order_preserving_huffman_greedy_trace;

const usz MAX_INPUT = 10;

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[offset + b] = (char)(bits >> (8 * b));
}

fn long order_preserving_huffman_greedy_trace(long* input, usz length,
        char* output, usz capacity) @export("order_preserving_huffman_greedy_trace") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n_value = input[0];
    if (n_value < 2 || n_value > 8 || length != (usz)n_value + 1) return -1;
    usz n = (usz)n_value;
    long[15] weight;
    int[15] left, right;
    int[8] active;
    for (usz i = 0; i < 15; i++) { left[i] = -1; right[i] = -1; }
    long total = 0;
    for (usz i = 0; i < n; i++) {
        if (input[i + 1] < 1 || input[i + 1] > 15) return -1;
        weight[i] = input[i + 1]; total += weight[i]; active[i] = (int)i;
    }
    if (total > 120) return -1;
    usz count = n, next_node = n;
    while (count > 1) {
        usz pair = 0;
        long best = weight[active[0]] + weight[active[1]];
        for (usz i = 1; i + 1 < count; i++) {
            long candidate = weight[active[i]] + weight[active[i + 1]];
            if (candidate < best) { pair = i; best = candidate; }
        }
        int a = active[pair], b = active[pair + 1];
        weight[next_node] = best; left[next_node] = a; right[next_node] = b;
        for (usz i = pair; i + 2 < count; i++) active[i] = active[i + 2];
        count -= 2;
        for (usz i = count; i > pair; i--) active[i] = active[i - 1];
        active[pair] = (int)next_node; count++; next_node++;
    }
    int[8] depths;
    int[16] stack_node, stack_depth;
    usz top = 1;
    stack_node[0] = active[0]; stack_depth[0] = 0;
    while (top > 0) {
        top--;
        int node = stack_node[top], depth = stack_depth[top];
        if ((usz)node < n) depths[node] = depth;
        else {
            stack_node[top] = left[node]; stack_depth[top] = depth + 1; top++;
            stack_node[top] = right[node]; stack_depth[top] = depth + 1; top++;
        }
    }
    long[10] words;
    words[0] = n_value;
    words[1] = 0;
    for (usz i = 0; i < n; i++) { words[1] += input[i + 1] * (long)depths[i]; words[i + 2] = (long)depths[i]; }
    usz needed = 8 * (n + 2);
    char[80] staged;
    for (usz i = 0; i < n + 2; i++) put_i64_le(&staged[0], 8 * i, words[i]);
    if (output == null || capacity < needed) return -2;
    for (usz i = 0; i < needed; i++) output[i] = staged[i];
    return (long)needed;
}

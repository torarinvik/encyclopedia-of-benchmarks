module virtual_tree;

const usz MAX_N = 32;
const usz MAX_K = 32;
const usz MAX_INPUT = 66;
const usz MAX_VIRTUAL = 32;
const usz MAX_CANDIDATES = 64;

fn void put_word(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[offset + b] = (char)(bits >> (8 * b));
}

fn usz lca(usz a, usz b, usz[MAX_N] parent, usz[MAX_N] depth) {
    while (depth[a] > depth[b]) a = parent[a];
    while (depth[b] > depth[a]) b = parent[b];
    while (a != b) { a = parent[a]; b = parent[b]; }
    return a;
}

fn bool ancestor(usz a, usz b, usz[MAX_N] tin, usz[MAX_N] tout) {
    return tin[a] <= tin[b] && tin[b] < tout[a];
}

fn void sort_by_tin(usz[MAX_CANDIDATES] items, usz count, usz[MAX_N] tin) {
    for (usz i = 1; i < count; i++) {
        usz value = items[i];
        usz j = i;
        while (j > 0 && tin[items[j - 1]] > tin[value]) { items[j] = items[j - 1]; j--; }
        items[j] = value;
    }
}

fn long virtual_tree(long* input, usz length, char* output, usz capacity) @export("virtual_tree") {
    if (input == null || length < 2 || length > MAX_INPUT || input[0] < 1 || input[0] > 32 ||
        input[1] < 0 || input[1] > 32 || input[1] > input[0]) return -1;
    usz n = (usz)input[0];
    usz k = (usz)input[1];
    if (length != n + k + 1) return -1;
    usz[MAX_N] parent = zeroed;
    usz[MAX_N] depth = zeroed;
    usz[MAX_N][MAX_N] children = zeroed;
    usz[MAX_N] child_count = zeroed;
    for (usz v = 1; v < n; v++) {
        long p = input[v + 1];
        if (p < 0 || p >= (long)n || p == (long)v) return -1;
        parent[v] = (usz)p;
        children[parent[v]][child_count[parent[v]]] = v;
        child_count[parent[v]]++;
    }
    usz[MAX_K] marks = zeroed;
    for (usz i = 0; i < k; i++) {
        long mark = input[n + 1 + i];
        if (mark < 0 || mark >= (long)n) return -1;
        marks[i] = (usz)mark;
        for (usz j = 0; j < i; j++) if (marks[j] == marks[i]) return -1;
    }
    usz[MAX_N] tin; usz[MAX_N] tout; usz[MAX_N] node_stack; usz[MAX_N] next_stack;
    for (usz v = 0; v < n; v++) { tin[v] = MAX_N; tout[v] = MAX_N; }
    usz timer = 0; usz top = 1; usz reached = 1;
    node_stack[0] = 0; next_stack[0] = 0; tin[0] = timer; timer++;
    while (top > 0) {
        usz frame = top - 1; usz vertex = node_stack[frame];
        if (next_stack[frame] == child_count[vertex]) { tout[vertex] = timer; top--; continue; }
        usz child = children[vertex][next_stack[frame]]; next_stack[frame]++;
        if (tin[child] != MAX_N) return -1;
        tin[child] = timer; timer++; depth[child] = depth[vertex] + 1; reached++;
        node_stack[top] = child; next_stack[top] = 0; top++;
    }
    if (reached != n) return -1;
    long[MAX_VIRTUAL * 3 + 1] words = zeroed;
    usz word_count = 1;
    if (k == 0) words[0] = 0;
    else {
        // Sort marked vertices by preorder before adjacent LCA closure.
        for (usz i = 1; i < k; i++) {
            usz value = marks[i]; usz j = i;
            while (j > 0 && tin[marks[j - 1]] > tin[value]) { marks[j] = marks[j - 1]; j--; }
            marks[j] = value;
        }
        usz[MAX_CANDIDATES] nodes = zeroed; usz count = 0;
        nodes[count] = 0; count++;
        for (usz i = 0; i < k; i++) { nodes[count] = marks[i]; count++; }
        for (usz i = 1; i < k; i++) { nodes[count] = lca(marks[i - 1], marks[i], parent, depth); count++; }
        sort_by_tin(nodes, count, tin);
        usz[MAX_VIRTUAL] unique = zeroed; usz unique_count = 0;
        for (usz i = 0; i < count; i++) {
            if (unique_count == 0 || unique[unique_count - 1] != nodes[i]) { unique[unique_count] = nodes[i]; unique_count++; }
        }
        words[0] = (long)unique_count;
        usz[MAX_VIRTUAL] stack = zeroed; usz stack_size = 0;
        for (usz i = 0; i < unique_count; i++) {
            usz vertex = unique[i];
            while (stack_size > 0 && !ancestor(stack[stack_size - 1], vertex, tin, tout)) stack_size--;
            usz vp = stack_size == 0 ? vertex : stack[stack_size - 1];
            words[word_count] = (long)vertex; word_count++;
            words[word_count] = (long)vp; word_count++;
            words[word_count] = (long)(depth[vertex] - depth[vp]); word_count++;
            stack[stack_size] = vertex; stack_size++;
        }
    }
    usz bytes = word_count * 8;
    if (output == null || capacity < bytes) return -2;
    for (usz i = 0; i < word_count; i++) put_word(output, i * 8, words[i]);
    return (long)bytes;
}

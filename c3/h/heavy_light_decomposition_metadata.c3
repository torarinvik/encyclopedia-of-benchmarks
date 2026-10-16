module heavy_light_decomposition_metadata;

const int MAX_VERTICES = 128;

fn void put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long heavy_light_decomposition_metadata(long* input, usz length, char* output, usz capacity)
    @export("heavy_light_decomposition_metadata") {
    if (input == null || length < 2) return -1;
    long nv = input[0], mv = input[1];
    if (nv < 1 || nv > MAX_VERTICES || mv != nv - 1 || length != 2 + 2 * (usz)mv) return -1;
    int n = (int)nv, m = (int)mv;
    int[MAX_VERTICES * MAX_VERTICES] adjacency;
    int[MAX_VERTICES] degree;
    for (int i = 0; i < MAX_VERTICES * MAX_VERTICES; i++) adjacency[i] = 0;
    for (int i = 0; i < MAX_VERTICES; i++) degree[i] = 0;
    for (int edge = 0; edge < m; edge++) {
        long uv = input[2 + 2 * edge], vv = input[3 + 2 * edge];
        if (uv < 0 || uv >= nv || vv < 0 || vv >= nv || uv == vv) return -1;
        int u = (int)uv, v = (int)vv;
        for (int i = 0; i < degree[u]; i++) if (adjacency[u * MAX_VERTICES + i] == v) return -1;
        adjacency[u * MAX_VERTICES + degree[u]++] = v;
        adjacency[v * MAX_VERTICES + degree[v]++] = u;
    }
    int[MAX_VERTICES] parent;
    int[MAX_VERTICES] order;
    int[MAX_VERTICES] stack;
    for (int v = 0; v < n; v++) parent[v] = -2;
    parent[0] = -1;
    int top = 0, order_count = 0;
    stack[top++] = 0;
    while (top > 0) {
        int vertex = stack[--top];
        order[order_count++] = vertex;
        int i = degree[vertex];
        while (i > 0) {
            i--;
            int child = adjacency[vertex * MAX_VERTICES + i];
            if (parent[child] == -2) {
                parent[child] = vertex;
                stack[top++] = child;
            }
        }
    }
    if (order_count != n) return -1;
    int[MAX_VERTICES] subtree_size;
    int[MAX_VERTICES] big_child;
    for (int index = n - 1; index >= 0; index--) {
        int vertex = order[index], best_size = 0;
        subtree_size[vertex] = 1;
        big_child[vertex] = -1;
        for (int i = 0; i < degree[vertex]; i++) {
            int child = adjacency[vertex * MAX_VERTICES + i];
            if (parent[child] != vertex) continue;
            subtree_size[vertex] += subtree_size[child];
            if (subtree_size[child] > best_size) {
                best_size = subtree_size[child];
                big_child[vertex] = child;
            }
        }
    }
    int[MAX_VERTICES] position;
    int[MAX_VERTICES] head;
    int[MAX_VERTICES] stack_head;
    top = 0;
    int next_position = 0;
    stack[top] = 0;
    stack_head[top++] = 0;
    while (top > 0) {
        top--;
        int vertex = stack[top], chain_head = stack_head[top];
        position[vertex] = next_position++;
        head[vertex] = chain_head;
        int i = degree[vertex];
        while (i > 0) {
            i--;
            int child = adjacency[vertex * MAX_VERTICES + i];
            if (parent[child] == vertex && child != big_child[vertex]) {
                stack[top] = child;
                stack_head[top++] = child;
            }
        }
        if (big_child[vertex] >= 0) {
            stack[top] = big_child[vertex];
            stack_head[top++] = chain_head;
        }
    }
    usz required = (1 + 3 * (usz)n) * 8;
    if (output == null || capacity < required) return -2;
    usz cursor = 0;
    put_i64(output, cursor++ * 8, nv);
    for (int vertex = 0; vertex < n; vertex++) {
        put_i64(output, cursor++ * 8, (long)position[vertex]);
        put_i64(output, cursor++ * 8, (long)head[vertex]);
        put_i64(output, cursor++ * 8, (long)big_child[vertex]);
    }
    return (long)required;
}

module vertex_add_range_contour_sum_on_tree;

const int MAX_N = 64;
const int MAX_Q = 128;
const int MAX_LEVEL = 8;
const usz MAX_INPUT_VALUES = 3 * (usz)MAX_N + 4 * (usz)MAX_Q + 1;
const long MAX_ABS_VALUE = 1000000;

struct Context {
    int n;
    int[MAX_N] degree;
    int[MAX_N][MAX_N] adjacent;
    bool[MAX_N] removed;
    int[MAX_N] parent;
    int[MAX_N] subtree_size;
    int[MAX_N][MAX_LEVEL] ancestor;
    int[MAX_N][MAX_LEVEL] distance;
    int[MAX_N][MAX_LEVEL] branch_for;
    int[MAX_N] path_length;
    int branch_count;
    long[MAX_N][MAX_N + 1] total;
    long[MAX_N][MAX_N + 1] branch;
}

fn int collect_component(Context* ctx, int start, int[MAX_N]* order) {
    int[MAX_N] stack;
    int top = 1, count = 0;
    ctx.parent[start] = -1;
    stack[0] = start;
    while (top > 0) {
        int u = stack[--top];
        order[count++] = u;
        for (int i = 0; i < ctx.degree[u]; i++) {
            int v = ctx.adjacent[u][i];
            if (ctx.removed[v] || v == ctx.parent[u]) continue;
            ctx.parent[v] = u;
            stack[top++] = v;
        }
    }
    for (int position = count - 1; position >= 0; position--) {
        int u = order[position];
        ctx.subtree_size[u] = 1;
        for (int i = 0; i < ctx.degree[u]; i++) {
            int v = ctx.adjacent[u][i];
            if (!ctx.removed[v] && ctx.parent[v] == u) ctx.subtree_size[u] += ctx.subtree_size[v];
        }
    }
    return count;
}

fn void decompose(Context* ctx, int start, int level) {
    int[MAX_N] order;
    int count = collect_component(ctx, start, &order);
    int center = start;
    for (int index = 0; index < count; index++) {
        int u = order[index];
        int largest = count - ctx.subtree_size[u];
        for (int i = 0; i < ctx.degree[u]; i++) {
            int v = ctx.adjacent[u][i];
            if (!ctx.removed[v] && ctx.parent[v] == u && ctx.subtree_size[v] > largest)
                largest = ctx.subtree_size[v];
        }
        if (2 * largest <= count) { center = u; break; }
    }
    ctx.removed[center] = true;
    ctx.ancestor[center][level] = center;
    ctx.distance[center][level] = 0;
    ctx.branch_for[center][level] = -1;
    ctx.path_length[center] = level + 1;
    for (int edge = 0; edge < ctx.degree[center]; edge++) {
        int root = ctx.adjacent[center][edge];
        if (ctx.removed[root]) continue;
        int branch_id = ctx.branch_count++;
        int[MAX_N] nodes, parents, distances;
        int top = 1;
        nodes[0] = root; parents[0] = center; distances[0] = 1;
        while (top > 0) {
            int u = nodes[--top], p = parents[top], d = distances[top];
            ctx.ancestor[u][level] = center;
            ctx.distance[u][level] = d;
            ctx.branch_for[u][level] = branch_id;
            ctx.path_length[u] = level + 1;
            for (int i = 0; i < ctx.degree[u]; i++) {
                int v = ctx.adjacent[u][i];
                if (ctx.removed[v] || v == p) continue;
                nodes[top] = v; parents[top] = u; distances[top] = d + 1; top++;
            }
        }
        decompose(ctx, root, level + 1);
    }
}

fn void fenwick_add(long* row, int position, long delta) {
    int index = position + 1;
    while (index <= MAX_N) { row[index] += delta; index += index & -index; }
}

fn long fenwick_prefix(long* row, int count) {
    long sum = 0;
    int index = count;
    while (index > 0) { sum += row[index]; index -= index & -index; }
    return sum;
}

fn long row_range(long* row, int left, int right) {
    if (left < 0) left = 0;
    if (right < 0) right = 0;
    if (left > MAX_N) left = MAX_N;
    if (right > MAX_N) right = MAX_N;
    if (right <= left) return 0;
    return fenwick_prefix(row, right) - fenwick_prefix(row, left);
}

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long vertex_add_range_contour_sum_on_tree(long* input, usz length,
    char* output, usz capacity) @export("vertex_add_range_contour_sum_on_tree") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    long nv = input[0], qv = input[1];
    if (nv < 1 || nv > MAX_N || qv < 0 || qv > MAX_Q) return -1;
    int n = (int)nv, q = (int)qv;
    if (length < 3 * (usz)n) return -1;

    Context ctx = zeroed;
    ctx.n = n;
    for (int v = 0; v < n; v++) for (int d = 0; d < MAX_LEVEL; d++) {
        ctx.ancestor[v][d] = -1;
        ctx.branch_for[v][d] = -1;
    }
    long[MAX_N] values;
    for (int v = 0; v < n; v++) {
        values[v] = input[2 + (usz)v];
        if (values[v] < -MAX_ABS_VALUE || values[v] > MAX_ABS_VALUE) return -1;
    }
    usz edge_start = 2 + (usz)n;
    for (int i = 0; i < n - 1; i++) {
        long uv = input[edge_start + 2 * (usz)i], vv = input[edge_start + 2 * (usz)i + 1];
        if (uv < 0 || uv >= nv || vv < 0 || vv >= nv || uv == vv) return -1;
        int u = (int)uv, v = (int)vv;
        for (int j = 0; j < ctx.degree[u]; j++) if (ctx.adjacent[u][j] == v) return -1;
        ctx.adjacent[u][ctx.degree[u]++] = v;
        ctx.adjacent[v][ctx.degree[v]++] = u;
    }
    bool[MAX_N] seen = zeroed;
    int[MAX_N] stack;
    int top = 1, visited = 0;
    stack[0] = 0; seen[0] = true;
    while (top > 0) {
        int u = stack[--top]; visited++;
        for (int i = 0; i < ctx.degree[u]; i++) {
            int v = ctx.adjacent[u][i];
            if (!seen[v]) { seen[v] = true; stack[top++] = v; }
        }
    }
    if (visited != n) return -1;

    int[MAX_Q] kinds, vertices;
    long[MAX_Q] first, second;
    int query_count = 0;
    usz cursor = 3 * (usz)n;
    for (int i = 0; i < q; i++) {
        if (cursor >= length) return -1;
        long op = input[cursor++];
        if (op == 0) {
            if (cursor + 2 > length) return -1;
            long p = input[cursor++], delta = input[cursor++];
            if (p < 0 || p >= nv || delta < -MAX_ABS_VALUE || delta > MAX_ABS_VALUE) return -1;
            kinds[i] = 0; vertices[i] = (int)p; first[i] = delta;
        } else if (op == 1) {
            if (cursor + 3 > length) return -1;
            long p = input[cursor++], left = input[cursor++], right = input[cursor++];
            if (p < 0 || p >= nv || left < 0 || left >= right || right > nv) return -1;
            kinds[i] = 1; vertices[i] = (int)p; first[i] = left; second[i] = right; query_count++;
        } else return -1;
    }
    if (cursor != length) return -1;

    decompose(&ctx, 0, 0);
    for (int v = 0; v < n; v++) for (int d = 0; d < ctx.path_length[v]; d++) {
        int c = ctx.ancestor[v][d], branch_id = ctx.branch_for[v][d];
        fenwick_add(&ctx.total[c][0], ctx.distance[v][d], values[v]);
        if (branch_id >= 0) fenwick_add(&ctx.branch[branch_id][0], ctx.distance[v][d], values[v]);
    }
    long[MAX_Q] answers;
    int answer_count = 0;
    for (int i = 0; i < q; i++) {
        int p = vertices[i];
        if (kinds[i] == 0) for (int d = 0; d < ctx.path_length[p]; d++) {
            int c = ctx.ancestor[p][d], branch_id = ctx.branch_for[p][d];
            fenwick_add(&ctx.total[c][0], ctx.distance[p][d], first[i]);
            if (branch_id >= 0) fenwick_add(&ctx.branch[branch_id][0], ctx.distance[p][d], first[i]);
        } else {
            long total = 0;
            for (int d = 0; d < ctx.path_length[p]; d++) {
                int c = ctx.ancestor[p][d], branch_id = ctx.branch_for[p][d];
                int left = (int)first[i] - ctx.distance[p][d];
                int right = (int)second[i] - ctx.distance[p][d];
                total += row_range(&ctx.total[c][0], left, right);
                if (branch_id >= 0) total -= row_range(&ctx.branch[branch_id][0], left, right);
            }
            answers[answer_count++] = total;
        }
    }
    usz output_bytes = 8 * (usz)answer_count;
    if (output_bytes > 0 && (output == null || capacity < output_bytes)) return -2;
    for (int i = 0; i < answer_count; i++) put_i64_le(output, 8 * (usz)i, answers[i]);
    return (long)output_bytes;
}

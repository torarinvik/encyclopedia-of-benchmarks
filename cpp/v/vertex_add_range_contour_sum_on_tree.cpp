#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_Q 128
#define MAX_LEVEL 8
#define MAX_INPUT_VALUES (3 * MAX_N + 4 * MAX_Q + 1)
#define MAX_ABS_VALUE INT64_C(1000000)

typedef struct {
    int n;
    int degree[MAX_N];
    int adjacent[MAX_N][MAX_N];
    int removed[MAX_N];
    int parent[MAX_N];
    int subtree_size[MAX_N];
    int ancestor[MAX_N][MAX_LEVEL];
    int distance[MAX_N][MAX_LEVEL];
    int branch_for[MAX_N][MAX_LEVEL];
    int path_length[MAX_N];
    int branch_count;
    int64_t total[MAX_N][MAX_N + 1];
    int64_t branch[MAX_N][MAX_N + 1];
} Context;

static size_t collect_component(Context *ctx, int start, int *order) {
    int stack[MAX_N];
    size_t top = 0, count = 0;
    ctx->parent[start] = -1;
    stack[top++] = start;
    while (top > 0) {
        int u = stack[--top];
        order[count++] = u;
        for (int i = 0; i < ctx->degree[u]; ++i) {
            int v = ctx->adjacent[u][i];
            if (ctx->removed[v] || v == ctx->parent[u]) continue;
            ctx->parent[v] = u;
            stack[top++] = v;
        }
    }
    for (size_t i = count; i > 0; --i) {
        int u = order[i - 1];
        ctx->subtree_size[u] = 1;
        for (int j = 0; j < ctx->degree[u]; ++j) {
            int v = ctx->adjacent[u][j];
            if (!ctx->removed[v] && ctx->parent[v] == u)
                ctx->subtree_size[u] += ctx->subtree_size[v];
        }
    }
    return count;
}

static void decompose(Context *ctx, int start, int level) {
    int order[MAX_N];
    size_t count = collect_component(ctx, start, order);
    int center = start;
    for (size_t i = 0; i < count; ++i) {
        int u = order[i];
        int largest = (int)count - ctx->subtree_size[u];
        for (int j = 0; j < ctx->degree[u]; ++j) {
            int v = ctx->adjacent[u][j];
            if (!ctx->removed[v] && ctx->parent[v] == u &&
                ctx->subtree_size[v] > largest)
                largest = ctx->subtree_size[v];
        }
        if (2 * largest <= (int)count) { center = u; break; }
    }

    ctx->removed[center] = 1;
    ctx->ancestor[center][level] = center;
    ctx->distance[center][level] = 0;
    ctx->branch_for[center][level] = -1;
    ctx->path_length[center] = level + 1;
    for (int i = 0; i < ctx->degree[center]; ++i) {
        int root = ctx->adjacent[center][i];
        if (ctx->removed[root]) continue;
        int branch = ctx->branch_count++;

        int stack_node[MAX_N], stack_parent[MAX_N], stack_distance[MAX_N];
        size_t top = 0;
        stack_node[top] = root;
        stack_parent[top] = center;
        stack_distance[top++] = 1;
        while (top > 0) {
            --top;
            int u = stack_node[top];
            int p = stack_parent[top];
            int d = stack_distance[top];
            ctx->ancestor[u][level] = center;
            ctx->distance[u][level] = d;
            ctx->branch_for[u][level] = branch;
            ctx->path_length[u] = level + 1;
            for (int j = 0; j < ctx->degree[u]; ++j) {
                int v = ctx->adjacent[u][j];
                if (ctx->removed[v] || v == p) continue;
                stack_node[top] = v;
                stack_parent[top] = u;
                stack_distance[top++] = d + 1;
            }
        }
        decompose(ctx, root, level + 1);
    }
}

static void fenwick_add(int64_t tree[MAX_N + 1], size_t position, int64_t delta) {
    for (size_t index = position + 1; index <= MAX_N; index += index & (~index + 1))
        tree[index] += delta;
}

static int64_t fenwick_prefix(const int64_t tree[MAX_N + 1], size_t count) {
    int64_t total = 0;
    for (size_t index = count; index > 0; index -= index & (~index + 1))
        total += tree[index];
    return total;
}

static int64_t row_range(const int64_t tree[MAX_N + 1], int left, int right) {
    if (left < 0) left = 0;
    if (right < 0) right = 0;
    if (left > MAX_N) left = MAX_N;
    if (right > MAX_N) right = MAX_N;
    if (right <= left) return 0;
    return fenwick_prefix(tree, (size_t)right) - fenwick_prefix(tree, (size_t)left);
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

extern "C" int64_t vertex_add_range_contour_sum_on_tree(const int64_t *input, size_t length,
    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q) return -1;
    const int n = (int)n_value, q = (int)q_value;
    if (length < (size_t)(3 * n)) return -1;

    Context ctx = {0};
    ctx.n = n;
    for (int v = 0; v < n; ++v)
        for (int d = 0; d < MAX_LEVEL; ++d) {
            ctx.ancestor[v][d] = -1;
            ctx.branch_for[v][d] = -1;
        }
    int64_t values[MAX_N];
    for (int v = 0; v < n; ++v) {
        values[v] = input[2 + v];
        if (values[v] < -MAX_ABS_VALUE || values[v] > MAX_ABS_VALUE) return -1;
    }

    const size_t edge_start = (size_t)(2 + n);
    for (int i = 0; i < n - 1; ++i) {
        int64_t uv = input[edge_start + (size_t)(2 * i)];
        int64_t vv = input[edge_start + (size_t)(2 * i + 1)];
        if (uv < 0 || uv >= n || vv < 0 || vv >= n || uv == vv) return -1;
        int u = (int)uv, v = (int)vv;
        for (int j = 0; j < ctx.degree[u]; ++j)
            if (ctx.adjacent[u][j] == v) return -1;
        ctx.adjacent[u][ctx.degree[u]++] = v;
        ctx.adjacent[v][ctx.degree[v]++] = u;
    }
    int seen[MAX_N] = {0}, stack[MAX_N];
    size_t top = 0, visited = 0;
    stack[top++] = 0;
    seen[0] = 1;
    while (top > 0) {
        int u = stack[--top];
        ++visited;
        for (int i = 0; i < ctx.degree[u]; ++i) {
            int v = ctx.adjacent[u][i];
            if (!seen[v]) { seen[v] = 1; stack[top++] = v; }
        }
    }
    if (visited != (size_t)n) return -1;

    int kind[MAX_Q], vertex[MAX_Q];
    int64_t first[MAX_Q], second[MAX_Q];
    int query_count = 0;
    size_t cursor = (size_t)(3 * n);
    for (int i = 0; i < q; ++i) {
        if (cursor >= length) return -1;
        int64_t op = input[cursor++];
        if (op == 0) {
            if (cursor + 2 > length) return -1;
            int64_t p = input[cursor++], delta = input[cursor++];
            if (p < 0 || p >= n || delta < -MAX_ABS_VALUE || delta > MAX_ABS_VALUE) return -1;
            kind[i] = 0; vertex[i] = (int)p; first[i] = delta; second[i] = 0;
        } else if (op == 1) {
            if (cursor + 3 > length) return -1;
            int64_t p = input[cursor++], left = input[cursor++], right = input[cursor++];
            if (p < 0 || p >= n || left < 0 || left >= right || right > n) return -1;
            kind[i] = 1; vertex[i] = (int)p; first[i] = left; second[i] = right;
            ++query_count;
        } else return -1;
    }
    if (cursor != length) return -1;

    decompose(&ctx, 0, 0);
    for (int v = 0; v < n; ++v) {
        for (int d = 0; d < ctx.path_length[v]; ++d) {
            int c = ctx.ancestor[v][d];
            int branch = ctx.branch_for[v][d];
            fenwick_add(ctx.total[c], (size_t)ctx.distance[v][d], values[v]);
            if (branch >= 0)
                fenwick_add(ctx.branch[branch], (size_t)ctx.distance[v][d], values[v]);
        }
    }

    int64_t answers[MAX_Q];
    int answer_count = 0;
    for (int i = 0; i < q; ++i) {
        int p = vertex[i];
        if (kind[i] == 0) {
            int64_t delta = first[i];
            for (int d = 0; d < ctx.path_length[p]; ++d) {
                int c = ctx.ancestor[p][d], branch = ctx.branch_for[p][d];
                size_t distance = (size_t)ctx.distance[p][d];
                fenwick_add(ctx.total[c], distance, delta);
                if (branch >= 0)
                    fenwick_add(ctx.branch[branch], distance, delta);
            }
        } else {
            int64_t total = 0;
            int left = (int)first[i], right = (int)second[i];
            for (int d = 0; d < ctx.path_length[p]; ++d) {
                int c = ctx.ancestor[p][d], branch = ctx.branch_for[p][d];
                int shifted_left = left - ctx.distance[p][d];
                int shifted_right = right - ctx.distance[p][d];
                total += row_range(ctx.total[c], shifted_left, shifted_right);
                if (branch >= 0)
                    total -= row_range(ctx.branch[branch], shifted_left, shifted_right);
            }
            answers[answer_count++] = total;
        }
    }

    const size_t output_bytes = (size_t)answer_count * 8;
    if (output_bytes > 0 && (output == NULL || capacity < output_bytes)) return -2;
    for (int i = 0; i < answer_count; ++i) put_i64_le(output, (size_t)i * 8, answers[i]);
    return (int64_t)output_bytes;
}

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_Q 32
#define MAX_INTERVALS (MAX_N + 2 * MAX_Q)
#define TREE_NODES (4 * MAX_Q + 8)

typedef struct {
    size_t kind;
    size_t a;
    size_t b;
    int64_t delta;
} TimeOp;

static size_t root_of(const size_t parent[MAX_N], size_t v) {
    while (parent[v] != v) v = parent[v];
    return v;
}

static void place_interval(size_t node, size_t left, size_t right,
                           size_t ql, size_t qr, size_t op_id,
                           size_t counts[TREE_NODES],
                           size_t bucket[TREE_NODES][MAX_INTERVALS]) {
    if (ql <= left && right <= qr) {
        bucket[node][counts[node]++] = op_id;
        return;
    }
    const size_t mid = left + (right - left) / 2;
    if (ql < mid)
        place_interval(node * 2, left, mid, ql, qr, op_id, counts, bucket);
    if (qr > mid)
        place_interval(node * 2 + 1, mid, right, ql, qr, op_id, counts, bucket);
}

static void unite(size_t u, size_t v, size_t parent[MAX_N],
                  size_t size[MAX_N], int64_t sum[MAX_N],
                  size_t hist_kind[MAX_INTERVALS],
                  size_t hist_a[MAX_INTERVALS], size_t hist_b[MAX_INTERVALS],
                  size_t hist_size[MAX_INTERVALS], int64_t hist_sum[MAX_INTERVALS],
                  size_t *hist_len) {
    size_t ru = root_of(parent, u), rv = root_of(parent, v);
    if (ru == rv) return;
    if (size[ru] < size[rv] || (size[ru] == size[rv] && ru > rv)) {
        const size_t tmp = ru; ru = rv; rv = tmp;
    }
    hist_kind[*hist_len] = 0;
    hist_a[*hist_len] = rv;
    hist_b[*hist_len] = ru;
    hist_size[*hist_len] = size[ru];
    hist_sum[*hist_len] = sum[ru];
    ++*hist_len;
    parent[rv] = ru;
    size[ru] += size[rv];
    sum[ru] += sum[rv];
}

static void add_vertex(size_t v, int64_t delta, size_t parent[MAX_N],
                       int64_t sum[MAX_N], size_t hist_kind[MAX_INTERVALS],
                       size_t hist_a[MAX_INTERVALS],
                       size_t hist_b[MAX_INTERVALS],
                       size_t hist_size[MAX_INTERVALS],
                       int64_t hist_sum[MAX_INTERVALS], size_t *hist_len) {
    const size_t r = root_of(parent, v);
    hist_kind[*hist_len] = 1;
    hist_a[*hist_len] = r;
    hist_sum[*hist_len] = sum[r];
    ++*hist_len;
    sum[r] += delta;
}

static void rollback(size_t mark, size_t parent[MAX_N], size_t size[MAX_N],
                     int64_t sum[MAX_N], const size_t hist_kind[MAX_INTERVALS],
                     const size_t hist_a[MAX_INTERVALS],
                     const size_t hist_b[MAX_INTERVALS],
                     const size_t hist_size[MAX_INTERVALS],
                     const int64_t hist_sum[MAX_INTERVALS], size_t *hist_len) {
    while (*hist_len > mark) {
        --*hist_len;
        const size_t k = hist_kind[*hist_len], a = hist_a[*hist_len];
        if (k == 0) {
            const size_t r = hist_b[*hist_len];
            parent[a] = a;
            size[r] = hist_size[*hist_len];
            sum[r] = hist_sum[*hist_len];
        } else {
            sum[a] = hist_sum[*hist_len];
        }
    }
}

static void visit_time(size_t node, size_t left, size_t right,
                       const TimeOp ops[MAX_INTERVALS],
                       const size_t bucket_count[TREE_NODES],
                       const size_t bucket[TREE_NODES][MAX_INTERVALS],
                       const int64_t event_op[MAX_Q], const int64_t event_a[MAX_Q],
                       size_t parent[MAX_N], size_t size[MAX_N], int64_t sum[MAX_N],
                       size_t hist_kind[MAX_INTERVALS], size_t hist_a[MAX_INTERVALS],
                       size_t hist_b[MAX_INTERVALS], size_t hist_size[MAX_INTERVALS],
                       int64_t hist_sum[MAX_INTERVALS], size_t *hist_len,
                       int64_t answers[MAX_Q]) {
    const size_t mark = *hist_len;
    for (size_t i = 0; i < bucket_count[node]; ++i) {
        const TimeOp op = ops[bucket[node][i]];
        if (op.kind == 0)
            unite(op.a, op.b, parent, size, sum, hist_kind, hist_a, hist_b,
                  hist_size, hist_sum, hist_len);
        else
            add_vertex(op.a, op.delta, parent, sum, hist_kind, hist_a, hist_b,
                       hist_size, hist_sum, hist_len);
    }
    if (right - left == 1) {
        if (event_op[left] == 3)
            answers[left] = sum[root_of(parent, (size_t)event_a[left])];
    } else {
        const size_t mid = left + (right - left) / 2;
        visit_time(node * 2, left, mid, ops, bucket_count, bucket, event_op,
                   event_a, parent, size, sum, hist_kind, hist_a, hist_b,
                   hist_size, hist_sum, hist_len, answers);
        visit_time(node * 2 + 1, mid, right, ops, bucket_count, bucket, event_op,
                   event_a, parent, size, sum, hist_kind, hist_a, hist_b,
                   hist_size, hist_sum, hist_len, answers);
    }
    rollback(mark, parent, size, sum, hist_kind, hist_a, hist_b, hist_size,
             hist_sum, hist_len);
}

static void store_i64_le(uint8_t *out, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) out[offset + i] = (uint8_t)(bits >> (8 * i));
}

int64_t dynamic_graph_vertex_add_component_sum(const int64_t *input, size_t length,
                                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 2 + MAX_N + 3 * MAX_Q + 1) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_Q) return -1;
    const size_t n = (size_t)input[0], q = (size_t)input[1];
    if (length != 2 + n + 3 * q) return -1;
    int64_t initial[MAX_N];
    for (size_t v = 0; v < n; ++v) {
        initial[v] = input[2 + v];
        if (initial[v] < 0 || initial[v] > 100) return -1;
    }

    int64_t event_op[MAX_Q], event_a[MAX_Q], event_b[MAX_Q];
    bool active[MAX_N][MAX_N] = {{false}};
    size_t edge_start[MAX_N][MAX_N] = {{0}};
    TimeOp ops[MAX_INTERVALS];
    size_t op_count = 0, query_count = 0;
    size_t edge_left[MAX_INTERVALS], edge_right[MAX_INTERVALS];
    for (size_t t = 0; t < q; ++t) {
        const size_t off = 2 + n + 3 * t;
        const int64_t op = input[off], a = input[off + 1], b = input[off + 2];
        event_op[t] = op; event_a[t] = a; event_b[t] = b;
        if (op == 0 || op == 1) {
            if (a < 0 || a >= (int64_t)n || b < 0 || b >= (int64_t)n || a == b) return -1;
            size_t u = (size_t)a, v = (size_t)b;
            if (u > v) { const size_t tmp = u; u = v; v = tmp; }
            if (op == 0) {
                if (active[u][v]) return -1;
                active[u][v] = true;
                edge_start[u][v] = t;
            } else {
                if (!active[u][v]) return -1;
                active[u][v] = false;
                if (edge_start[u][v] < t) {
                    ops[op_count] = (TimeOp){0, u, v, 0};
                    edge_left[op_count] = edge_start[u][v]; edge_right[op_count] = t;
                    ++op_count;
                }
            }
        } else if (op == 2) {
            if (a < 0 || a >= (int64_t)n || b < 0 || b > 100) return -1;
            if (b != 0 && t < q) {
                ops[op_count] = (TimeOp){1, (size_t)a, 0, b};
                edge_left[op_count] = t; edge_right[op_count] = q;
                ++op_count;
            }
        } else if (op == 3) {
            if (a < 0 || a >= (int64_t)n || b != 0) return -1;
            ++query_count;
        } else return -1;
    }
    for (size_t u = 0; u < n; ++u) for (size_t v = u + 1; v < n; ++v) {
        if (active[u][v] && edge_start[u][v] < q) {
            ops[op_count] = (TimeOp){0, u, v, 0};
            edge_left[op_count] = edge_start[u][v]; edge_right[op_count] = q;
            ++op_count;
        }
    }
    if (q != 0) for (size_t v = 0; v < n; ++v) if (initial[v] != 0) {
        ops[op_count] = (TimeOp){1, v, 0, initial[v]};
        edge_left[op_count] = 0; edge_right[op_count] = q;
        ++op_count;
    }

    if (output == NULL || capacity < 8 * query_count) return -2;
    size_t bucket_count[TREE_NODES] = {0};
    size_t bucket[TREE_NODES][MAX_INTERVALS];
    if (q != 0) for (size_t i = 0; i < op_count; ++i)
        if (edge_left[i] < edge_right[i])
            place_interval(1, 0, q, edge_left[i], edge_right[i], i,
                           bucket_count, bucket);

    size_t parent[MAX_N], set_size[MAX_N];
    int64_t component_sum[MAX_N] = {0};
    for (size_t v = 0; v < n; ++v) { parent[v] = v; set_size[v] = 1; }
    size_t hist_kind[MAX_INTERVALS], hist_a[MAX_INTERVALS], hist_b[MAX_INTERVALS];
    size_t hist_size[MAX_INTERVALS], hist_len = 0;
    int64_t hist_sum[MAX_INTERVALS], answers[MAX_Q] = {0};
    if (q != 0) visit_time(1, 0, q, ops, bucket_count, bucket, event_op,
                           event_a, parent, set_size, component_sum, hist_kind,
                           hist_a, hist_b, hist_size, hist_sum, &hist_len, answers);

    size_t written = 0;
    for (size_t t = 0; t < q; ++t) if (event_op[t] == 3) {
        store_i64_le(output, written, answers[t]);
        written += 8;
    }
    return (int64_t)written;
}

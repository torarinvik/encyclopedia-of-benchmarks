/* Bounded graph ADT trace preserving adjacency-list insertion order. */
#include <stddef.h>
#include <stdint.h>

static void put_i64(uint8_t *out, size_t i, int64_t v) {
    uint64_t bits = (uint64_t)v;
    for (size_t b = 0; b < 8; ++b) out[i * 8 + b] = (uint8_t)(bits >> (8 * b));
}
static int find_vertex(const int *order, int n, int v) {
    for (int i = 0; i < n; ++i) if (order[i] == v) return i;
    return -1;
}
static int find_neighbor(const int rows[32][34], const int *degree, int u, int v) {
    for (int i = 0; i < degree[u]; ++i) if (rows[u][i] == v) return i;
    return -1;
}
static void del_neighbor(int rows[32][34], int *degree, int u, int at) {
    for (int i = at; i + 1 < degree[u]; ++i) rows[u][i] = rows[u][i + 1];
    --degree[u];
}
int64_t graph_adjacency_list(const int64_t *in, size_t len, uint8_t *out, size_t cap) {
    if (!in || len < 4) return -1;
    int64_t direct = in[0], n0 = in[1];
    if ((direct != 0 && direct != 1) || n0 < 0 || n0 > 32 || len < (size_t)(4 + n0)) return -1;
    int order[32], rows[32][34] = {{0}}, degree[32] = {0};
    int n = (int)n0, directed = (int)direct;
    size_t k = 2;
    for (int i = 0; i < n; ++i) {
        int64_t v = in[k++];
        if (v < 0 || v >= 32) return -1;
        for (int j = 0; j < i; ++j) if (order[j] == (int)v) return -1;
        order[i] = (int)v;
    }
    int64_t ec0 = in[k++];
    if (ec0 < 0 || ec0 > 1024 || len < k + 2 * (size_t)ec0 + 1) return -1;
    for (int i = 0; i < ec0; ++i) {
        int64_t aa = in[k++], bb = in[k++];
        if (aa < 0 || aa >= 32 || bb < 0 || bb >= 32) return -1;
        int a = (int)aa, b = (int)bb;
        if (find_vertex(order, n, a) < 0 || find_vertex(order, n, b) < 0 || find_neighbor(rows, degree, a, b) >= 0) return -1;
        rows[a][degree[a]++] = b;
        if (!directed) rows[b][degree[b]++] = a;
    }
    int64_t oc0 = in[k++];
    if (oc0 < 0 || oc0 > 64 || len != k + 3 * (size_t)oc0) return -1;
    int oc = (int)oc0, result[64];
    for (int i = 0; i < oc; ++i) {
        int64_t op = in[k++], aa = in[k++], bb = in[k++];
        if (op == 0) {
            if (aa < 0 || aa >= 32 || bb != 0 || find_vertex(order, n, (int)aa) >= 0 || n >= 32) return -1;
            order[n] = (int)aa; degree[(int)aa] = 0; ++n; result[i] = 1;
        } else if (op == 1) {
            if (aa < 0 || aa >= 32 || bb != 0) return -1;
            int at = find_vertex(order, n, (int)aa); if (at < 0) return -1;
            if (directed) {
                for (int u = 0; u < n; ++u) { int x; while ((x = find_neighbor(rows, degree, order[u], (int)aa)) >= 0) del_neighbor(rows, degree, order[u], x); }
            } else {
                int u = (int)aa;
                while (degree[u] > 0) { int v = rows[u][degree[u] - 1]; --degree[u]; if (v != u) { int x = find_neighbor(rows, degree, v, u); if (x >= 0) del_neighbor(rows, degree, v, x); } }
            }
            for (int j = at; j + 1 < n; ++j) order[j] = order[j + 1];
            degree[(int)aa] = 0; --n; result[i] = 1;
        } else if (op == 2 || op == 3 || op == 5) {
            if (aa < 0 || aa >= 32 || bb < 0 || bb >= 32) return -1;
            int u = (int)aa, v = (int)bb, ui = find_vertex(order, n, u), vi = find_vertex(order, n, v);
            if (ui < 0 || vi < 0) return -1;
            int x = find_neighbor(rows, degree, u, v);
            if (op == 5) result[i] = x >= 0;
            else if (op == 2) { if (x >= 0) return -1; rows[u][degree[u]++] = v; if (!directed) rows[v][degree[v]++] = u; result[i] = 1; }
            else { if (x < 0) return -1; del_neighbor(rows, degree, u, x); if (!directed) { int y = find_neighbor(rows, degree, v, u); if (y < 0) return -1; del_neighbor(rows, degree, v, y); } result[i] = 1; }
        } else if (op == 4) {
            if (aa < 0 || aa >= 32 || bb != 0) return -1;
            result[i] = find_vertex(order, n, (int)aa) >= 0;
        } else if (op == 6) {
            if (aa != 0 || bb != 0) return -1;
            n = 0; for (int u = 0; u < 32; ++u) degree[u] = 0; result[i] = 1;
        } else return -1;
    }
    size_t words = 2 + (size_t)oc;
    for (int i = 0; i < n; ++i) words += 2 + (size_t)degree[i];
    if (!out || cap < words * 8) return -2;
    size_t w = 0; put_i64(out, w++, oc); for (int i = 0; i < oc; ++i) put_i64(out, w++, result[i]);
    put_i64(out, w++, n);
    for (int i = 0; i < n; ++i) { put_i64(out, w++, order[i]); put_i64(out, w++, degree[i]); for (int j = 0; j < degree[i]; ++j) put_i64(out, w++, rows[i][j]); }
    return (int64_t)(words * 8);
}

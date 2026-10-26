module metric_tsp_tree_doubling;

const usz MAX_N = 8;
const usz MAX_INPUT = 65;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b += 1) { output[offset + b] = (char)(bits & 255); bits >>= 8; }
}

long metric_tsp_tree_doubling(long* input, usz length, char* output, usz capacity)
        @export("metric_tsp_tree_doubling") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n64 = input[0];
    if (n64 < 1 || n64 > (long)MAX_N || length != 1 + (usz)n64 * (usz)n64) return -1;
    usz n = (usz)n64;
    long[MAX_N][MAX_N] d = zeroed;
    for (usz u = 0; u < n; u += 1) for (usz v = 0; v < n; v += 1) {
        long w = input[1 + u * n + v];
        if (w < 0 || w > 10000 || (u == v && w != 0)) return -1;
        d[u][v] = w;
    }
    for (usz u = 0; u < n; u += 1) for (usz v = u + 1; v < n; v += 1) if (d[u][v] != d[v][u]) return -1;
    for (usz u = 0; u < n; u += 1) for (usz v = 0; v < n; v += 1)
        for (usz k = 0; k < n; k += 1) if (d[u][v] > d[u][k] + d[k][v]) return -1;
    usz output_bytes = 8 * (n + 2);
    if (output == null || capacity < output_bytes) return -2;
    bool[MAX_N][MAX_N] processed = zeroed, tree = zeroed;
    usz[MAX_N] parent = zeroed;
    for (usz i = 0; i < n; i += 1) parent[i] = i;
    usz accepted = 0, edge_count = n * (n - 1) / 2;
    for (usz step = 0; step < edge_count && accepted + 1 < n; step += 1) {
        usz bu = 0, bv = 0;
        long bw = 9223372036854775807;
        for (usz u = 0; u < n; u += 1) for (usz v = u + 1; v < n; v += 1)
            if (!processed[u][v] && d[u][v] < bw) { bw = d[u][v]; bu = u; bv = v; }
        processed[bu][bv] = true;
        usz ru = bu, rv = bv;
        while (parent[ru] != ru) ru = parent[ru];
        while (parent[rv] != rv) rv = parent[rv];
        if (ru != rv) { parent[rv] = ru; tree[bu][bv] = true; tree[bv][bu] = true; accepted += 1; }
    }
    usz[MAX_N] stack = zeroed, order = zeroed;
    bool[MAX_N] visited = zeroed;
    usz top = 1, count = 0; stack[0] = 0;
    while (top > 0) {
        top -= 1;
        usz v = stack[top];
        if (visited[v]) continue;
        visited[v] = true; order[count] = v; count += 1;
        usz rev = n;
        while (rev > 0) { rev -= 1; if (tree[v][rev] && !visited[rev]) { stack[top] = rev; top += 1; } }
    }
    long cost = 0;
    for (usz i = 0; i + 1 < n; i += 1) cost += d[order[i]][order[i + 1]];
    cost += d[order[n - 1]][0];
    store_i64_le(output, 0, cost);
    for (usz i = 0; i < n; i += 1) store_i64_le(output, 8 * (i + 1), (long)order[i]);
    store_i64_le(output, 8 * (n + 1), 0);
    return (long)output_bytes;
}

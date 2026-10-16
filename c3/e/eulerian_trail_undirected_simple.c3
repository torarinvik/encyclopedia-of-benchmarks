module eulerian_trail_undirected_simple;
const usz MAX_V = 10;
const usz MAX_E = 45;
fn void dfs(long u, long[MAX_V][MAX_E] neighbors, long[MAX_V] degree, bool[MAX_V][MAX_V] seen, long[MAX_E + 1] path, usz* count) {
    path[*count] = u; *count += 1;
    for (usz i = 0; i < degree[(usz)u]; i++) { long v = neighbors[(usz)u][i]; if (!seen[(usz)u][(usz)v]) { seen[(usz)u][(usz)v] = true; seen[(usz)v][(usz)u] = true; dfs(v, neighbors, degree, seen, path, count); } }
}
fn void put_i64(char* output, usz slot, long value) { ulong bits = (ulong)value; for (usz i = 0; i < 8; i++) output[slot * 8 + i] = (char)(bits >> (i * 8)); }
fn long eulerian_trail_undirected_simple(long* input, usz length, char* output, usz capacity) @export("eulerian_trail_undirected_simple") {
    if (input == null || length < 2 || input[0] < 2 || input[0] > 10 || input[1] < 0 || input[1] > 45) return -1;
    usz n = (usz)input[0], m = (usz)input[1]; if (length != 2 + 2 * m) return -1;
    long[MAX_V][MAX_E] neighbors; long[MAX_V] degree; bool[MAX_V][MAX_V] adjacent;
    for (usz i = 0; i < m; i++) { long a = input[2 + 2 * i], b = input[3 + 2 * i]; if (a < 0 || b < 0 || (usz)a >= n || (usz)b >= n || a == b) return -1; usz u = (usz)a, v = (usz)b; if (adjacent[u][v]) return -1; adjacent[u][v] = true; adjacent[v][u] = true; neighbors[u][degree[u]] = (long)v; degree[u]++; neighbors[v][degree[v]] = (long)u; degree[v]++; }
    usz odd = 0, start = 1; for (usz v = 0; v < n; v++) if (degree[v] % 2 == 1) { odd++; start = v; } if (odd != 0 && odd != 2) return -1; long status = odd == 0 ? 1 : 2; if (status == 1) start = 1;
    if (m > 0) { if (status == 1 && degree[1] == 0) return -1; bool[MAX_V] reached; long[MAX_V] stack; usz top = 0; stack[top] = (long)start; top++; reached[start] = true; while (top > 0) { top--; usz u = (usz)stack[top]; for (usz i = 0; i < degree[u]; i++) { usz v = (usz)neighbors[u][i]; if (!reached[v]) { reached[v] = true; stack[top] = (long)v; top++; } } } for (usz v = 0; v < n; v++) if (degree[v] > 0 && !reached[v]) return -1; }
    bool[MAX_V][MAX_V] seen; long[MAX_E + 1] path; usz count = 0; dfs((long)start, neighbors, degree, seen, path, &count); if (count != m + 1) return -1; usz bytes = (2 + count) * 8; if (output == null || capacity < bytes) return -2; put_i64(output, 0, status); put_i64(output, 1, (long)count); for (usz i = 0; i < count; i++) put_i64(output, 2 + i, path[i]); return (long)bytes;
}

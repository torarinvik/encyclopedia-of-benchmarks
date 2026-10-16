module binary_lifting_kth_ancestor;
const usz MAX_NODES = 256;
const usz MAX_QUERIES = 1024;
const usz LEVELS = 9;
fn void put_i64(char* output, usz slot, long value) { ulong bits = (ulong)value; for (usz i = 0; i < 8; i++) output[slot * 8 + i] = (char)(bits >> (i * 8)); }
fn long binary_lifting_kth_ancestor(long* input, usz length, char* output, usz capacity) @export("binary_lifting_kth_ancestor") {
 if (input == null || length < 4 || input[0] < 1 || input[0] > 256) return -1;
 usz n = (usz)input[0]; if (input[1] < 0 || (usz)input[1] >= n || input[2] != (long)(n - 1) || input[3] < 0 || input[3] > 1024) return -1;
 usz m = (usz)input[2], q = (usz)input[3], query_offset = 4 + 2 * m; if (length != query_offset + 2 * q) return -1; usz root = (usz)input[1];
 bool[MAX_NODES][MAX_NODES] adj;
 for (usz e = 0; e < m; e++) { long a = input[4 + 2 * e], b = input[5 + 2 * e]; if (a < 0 || b < 0 || (usz)a >= n || (usz)b >= n || a == b) return -1; adj[(usz)a][(usz)b] = true; adj[(usz)b][(usz)a] = true; }
 for (usz i = 0; i < q; i++) { long v = input[query_offset + 2 * i], k = input[query_offset + 2 * i + 1]; if (v < 0 || (usz)v >= n || k < 0) return -1; }
 usz[MAX_NODES] stack; long[MAX_NODES] parent; usz[LEVELS][MAX_NODES] up; for (usz i = 0; i < n; i++) parent[i] = -1; parent[root] = (long)root; up[0][root] = root; usz top = 0, reached = 0; stack[top] = root; top++;
 while (top > 0) { top--; usz u = stack[top]; reached++; for (usz v = 0; v < n; v++) if (adj[u][v]) { if ((long)v == parent[u]) continue; if (parent[v] != -1) return -1; parent[v] = (long)u; up[0][v] = u; stack[top] = v; top++; } }
 if (reached != n) return -1;
 for (usz level = 1; level < LEVELS; level++) for (usz v = 0; v < n; v++) up[level][v] = up[level - 1][up[level - 1][v]];
 usz bytes = (1 + q) * 8; if (output == null || capacity < bytes) return -2; put_i64(output, 0, (long)q);
 for (usz i = 0; i < q; i++) { usz v = (usz)input[query_offset + 2 * i]; ulong k = (ulong)input[query_offset + 2 * i + 1]; if (k >= n) v = root; else for (usz bit = 0; bit < LEVELS; bit++) if (k & ((ulong)1 << bit)) v = up[bit][v]; put_i64(output, 1 + i, (long)v); }
 return (long)bytes;
}

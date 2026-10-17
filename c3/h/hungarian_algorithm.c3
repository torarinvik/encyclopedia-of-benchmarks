module hungarian_algorithm;

fn void store_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz b = 0; b < 4; b++) { output[offset + b] = (char)(bits & 255); bits >>= 8; }
}

long hungarian_algorithm(int* input, usz length, char* output, usz capacity) @export("hungarian_algorithm") {
    if (input == null || length < 2 || length > 67) return -1;
    int rows = input[0], cols = input[1];
    if (rows < 1 || rows > 8 || cols < 1 || cols > 8 || length != (usz)(2 + rows * cols)) return -1;
    for (usz k = 0; k < (usz)(rows * cols); k++) if (input[2+k] < 0 || input[2+k] > 1000) return -1;
    int n = rows > cols ? rows : cols;
    int[81] a; int[9] u, v, p, way;
    for (int i = 0; i < rows; i++) for (int j = 0; j < cols; j++) a[i*9+j] = input[2+i*cols+j];
    for (int i = 1; i <= n; i++) {
        p[0] = i; int j0 = 0; int[9] minv; bool[9] used;
        for (int j = 0; j <= n; j++) minv[j] = 2147483647;
        while (true) {
            used[j0] = true; int i0 = p[j0], delta = 2147483647, j1 = 0;
            for (int j = 1; j <= n; j++) if (!used[j]) {
                int cur = a[(i0-1)*9+j-1] - u[i0] - v[j];
                if (cur < minv[j]) { minv[j] = cur; way[j] = j0; }
                if (minv[j] < delta) { delta = minv[j]; j1 = j; }
            }
            for (int j = 0; j <= n; j++) { if (used[j]) { u[p[j]] += delta; v[j] -= delta; } else minv[j] -= delta; }
            j0 = j1; if (p[j0] == 0) break;
        }
        while (true) { int j1 = way[j0]; p[j0] = p[j1]; j0 = j1; if (j0 == 0) break; }
    }
    int[9] matched; for (int i = 0; i < 9; i++) matched[i] = -1;
    for (int j = 1; j <= n; j++) if (p[j] != 0) matched[p[j]-1] = j-1;
    int[8] assignments; int total = 0;
    for (int i = 0; i < rows; i++) { int j = matched[i]; assignments[i] = j >= 0 && j < cols ? j : -1; if (assignments[i] >= 0) total += input[2+i*cols+assignments[i]]; }
    usz bytes = (usz)(4 * (rows + 1));
    if (output == null || capacity < bytes) return -2;
    for (int i = 0; i < rows; i++) store_i32_le(output, (usz)(4*i), assignments[i]);
    store_i32_le(output, (usz)(4*rows), total);
    return (long)bytes;
}

module gapbs_ordered_triangle_count;

const long MAX_N = 16;

// Clean-room bounded port of GAPBS OrderedCount; see package LICENSE.txt.
fn long gapbs_ordered_triangle_count(long* input, usz length) @export("gapbs_ordered_triangle_count") {
    if (input == null || length < 2 || length > 257) return -1;
    long n = input[0];
    if (n < 1 || n > MAX_N || length != 1 + (usz)(n * n)) return -1;
    long[256] adjacency;
    long[256] neighbors;
    long[16] degree;
    for (usz q = 0; q < 256; q++) { adjacency[q] = 0; neighbors[q] = 0; }
    for (usz q = 0; q < 16; q++) degree[q] = 0;
    for (long u = 0; u < n; u++) {
        for (long v = 0; v < n; v++) {
            long edge = input[1 + (usz)(u * n + v)];
            if (edge != 0 && edge != 1) return -1;
            if (u == v && edge != 0) return -1;
            adjacency[(usz)(u * n + v)] = edge;
        }
    }
    for (long u = 0; u < n; u++) {
        for (long v = u + 1; v < n; v++)
            if (adjacency[(usz)(u * n + v)] != adjacency[(usz)(v * n + u)]) return -1;
    }
    for (long u = 0; u < n; u++) {
        for (long v = 0; v < n; v++) {
            if (adjacency[(usz)(u * n + v)] != 0) {
                neighbors[(usz)(u * MAX_N + degree[(usz)u])] = v;
                degree[(usz)u]++;
            }
        }
    }
    long triangles = 0;
    for (long u = 0; u < n; u++) {
        for (long vi = 0; vi < degree[(usz)u]; vi++) {
            long v = neighbors[(usz)(u * MAX_N + vi)];
            if (v > u) break;
            long edge_pos = 0;
            for (long wi = 0; wi < degree[(usz)u]; wi++) {
                long w = neighbors[(usz)(u * MAX_N + wi)];
                if (w > v) break;
                while (edge_pos < degree[(usz)v] && neighbors[(usz)(v * MAX_N + edge_pos)] < w) edge_pos++;
                if (edge_pos < degree[(usz)v] && neighbors[(usz)(v * MAX_N + edge_pos)] == w) triangles++;
            }
        }
    }
    return triangles;
}

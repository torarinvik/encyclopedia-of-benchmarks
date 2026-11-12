#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 8
#define MAX_EDGES (MAX_POINTS * (MAX_POINTS - 1) / 2)
#define MAX_INPUT_LENGTH (1 + 2 * MAX_POINTS + 1)
#define MAX_OUTPUT_WORDS (2 * MAX_POINTS - 1)

typedef struct { int64_t x, y; } point;
typedef struct { int u, v; int64_t weight; } mst_edge;

static int64_t orientation(point a, point b, point c) {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

static int64_t incircle(point a, point b, point c, point d) {
    const int64_t ax = a.x - d.x, ay = a.y - d.y;
    const int64_t bx = b.x - d.x, by = b.y - d.y;
    const int64_t cx = c.x - d.x, cy = c.y - d.y;
    return (ax * ax + ay * ay) * (bx * cy - by * cx)
         - (bx * bx + by * by) * (ax * cy - ay * cx)
         + (cx * cx + cy * cy) * (ax * by - ay * bx);
}

static int valid_general_position(const point points[MAX_POINTS], int count) {
    for (int a = 0; a < count; ++a) {
        for (int b = a + 1; b < count; ++b)
            if (points[a].x == points[b].x && points[a].y == points[b].y) return 0;
    }
    for (int a = 0; a < count; ++a) for (int b = a + 1; b < count; ++b)
        for (int c = b + 1; c < count; ++c) {
            if (orientation(points[a], points[b], points[c]) == 0) return 0;
            for (int d = 0; d < count; ++d)
                if (d != a && d != b && d != c &&
                    incircle(points[a], points[b], points[c], points[d]) == 0) return 0;
        }
    return 1;
}

static int find_root(int parent[MAX_POINTS], int vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t euclidean_mst(const int64_t *input, size_t length,
                      uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t raw_count = input[0];
    if (raw_count < 1 || raw_count > MAX_POINTS || length != (size_t)(1 + 2 * raw_count)) return -1;
    const int count = (int)raw_count;
    point points[MAX_POINTS] = {{0, 0}};
    for (int i = 0; i < count; ++i) {
        points[i].x = input[1 + 2 * i];
        points[i].y = input[2 + 2 * i];
        if (points[i].x < -10 || points[i].x > 10 || points[i].y < -10 || points[i].y > 10) return -1;
    }
    if (!valid_general_position(points, count)) return -1;
    const size_t output_words = (size_t)(2 * count - 1);
    const size_t output_bytes = 8 * output_words;
    if (output == NULL || output_capacity < output_bytes) return -2;

    uint8_t candidate[MAX_POINTS][MAX_POINTS] = {{0}};
    if (count == 2) candidate[0][1] = candidate[1][0] = 1;
    for (int a = 0; a < count; ++a) for (int b = a + 1; b < count; ++b)
        for (int c = b + 1; c < count; ++c) {
            const int64_t turn = orientation(points[a], points[b], points[c]);
            int empty = 1;
            for (int d = 0; d < count; ++d) {
                if (d == a || d == b || d == c) continue;
                const int64_t determinant = incircle(points[a], points[b], points[c], points[d]);
                if ((determinant > 0) == (turn > 0)) { empty = 0; break; }
            }
            if (empty) {
                candidate[a][b] = candidate[b][a] = 1;
                candidate[a][c] = candidate[c][a] = 1;
                candidate[b][c] = candidate[c][b] = 1;
            }
        }

    mst_edge edges[MAX_EDGES];
    int edge_count = 0;
    for (int u = 0; u < count; ++u) for (int v = u + 1; v < count; ++v) if (candidate[u][v]) {
        const int64_t dx = points[u].x - points[v].x, dy = points[u].y - points[v].y;
        mst_edge edge = {u, v, dx * dx + dy * dy};
        int position = edge_count++;
        while (position > 0) {
            const mst_edge previous = edges[position - 1];
            if (previous.weight < edge.weight ||
                (previous.weight == edge.weight && (previous.u < edge.u ||
                 (previous.u == edge.u && previous.v <= edge.v)))) break;
            edges[position] = previous;
            --position;
        }
        edges[position] = edge;
    }

    int parent[MAX_POINTS], size[MAX_POINTS];
    for (int i = 0; i < count; ++i) { parent[i] = i; size[i] = 1; }
    int64_t words[MAX_OUTPUT_WORDS] = {0};
    words[0] = count - 1;
    int selected = 0;
    for (int i = 0; i < edge_count && selected < count - 1; ++i) {
        int left = find_root(parent, edges[i].u), right = find_root(parent, edges[i].v);
        if (left == right) continue;
        if (size[left] < size[right]) { int temporary = left; left = right; right = temporary; }
        parent[right] = left; size[left] += size[right];
        words[1 + 2 * selected] = edges[i].u;
        words[2 + 2 * selected] = edges[i].v;
        ++selected;
    }
    if (selected != count - 1) return -1;
    for (size_t word = 0; word < output_words; ++word) store_i64_le(output, 8 * word, words[word]);
    return (int64_t)output_bytes;
}

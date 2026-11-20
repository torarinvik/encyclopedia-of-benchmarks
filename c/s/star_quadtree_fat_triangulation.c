#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_VERTICES = 5, MAX_TRIANGLES = 4, MAX_EDGES = 8, MAX_PAIRS = 64,
       MAX_DEPTH = 2, MAX_INPUT = 25, MAX_OUTPUT = 1032 };

typedef struct {
    int vertices[MAX_VERTICES][2];
    int triangles[MAX_TRIANGLES][3];
    int edges[MAX_EDGES][2];
    int vertex_count, triangle_count, edge_count;
    int pairs[MAX_PAIRS][2];
    int pair_count;
    bool failed;
} State;

static int orient(int ax, int ay, int bx, int by, int cx, int cy) {
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

static bool between(int a, int b, int p) {
    return (a <= p && p <= b) || (b <= p && p <= a);
}

static bool on_segment(int ax, int ay, int bx, int by, int px, int py) {
    return between(ax, bx, px) && between(ay, by, py);
}

static bool segments_intersect(int ax, int ay, int bx, int by,
                               int cx, int cy, int dx, int dy) {
    int o1 = orient(ax, ay, bx, by, cx, cy);
    int o2 = orient(ax, ay, bx, by, dx, dy);
    int o3 = orient(cx, cy, dx, dy, ax, ay);
    int o4 = orient(cx, cy, dx, dy, bx, by);
    if (((o1 < 0 && o2 > 0) || (o1 > 0 && o2 < 0)) &&
        ((o3 < 0 && o4 > 0) || (o3 > 0 && o4 < 0))) return true;
    return (o1 == 0 && on_segment(ax, ay, bx, by, cx, cy)) ||
           (o2 == 0 && on_segment(ax, ay, bx, by, dx, dy)) ||
           (o3 == 0 && on_segment(cx, cy, dx, dy, ax, ay)) ||
           (o4 == 0 && on_segment(cx, cy, dx, dy, bx, by));
}

static bool edge_hits_box(const State *s, int edge_id,
                          int xmin, int ymin, int xmax, int ymax) {
    int a = s->edges[edge_id][0], b = s->edges[edge_id][1];
    int ax = s->vertices[a][0], ay = s->vertices[a][1];
    int bx = s->vertices[b][0], by = s->vertices[b][1];
    if ((xmin <= ax && ax <= xmax && ymin <= ay && ay <= ymax) ||
        (xmin <= bx && bx <= xmax && ymin <= by && by <= ymax)) return true;
    return segments_intersect(ax, ay, bx, by, xmin, ymin, xmax, ymin) ||
           segments_intersect(ax, ay, bx, by, xmax, ymin, xmax, ymax) ||
           segments_intersect(ax, ay, bx, by, xmax, ymax, xmin, ymax) ||
           segments_intersect(ax, ay, bx, by, xmin, ymax, xmin, ymin);
}

static bool stop_cell(const State *s, int xmin, int ymin, int xmax, int ymax) {
    bool touched[MAX_EDGES] = {false};
    int touched_count = 0;
    for (int e = 0; e < s->edge_count; ++e) {
        touched[e] = edge_hits_box(s, e, xmin, ymin, xmax, ymax);
        if (touched[e]) ++touched_count;
    }
    if (touched_count == 0) return true;
    for (int v = 0; v < s->vertex_count; ++v) {
        bool common = true;
        for (int e = 0; e < s->edge_count; ++e) {
            if (touched[e] && s->edges[e][0] != v && s->edges[e][1] != v) {
                common = false;
                break;
            }
        }
        if (common) return true;
    }
    return false;
}

static bool point_in_triangle(int px, int py, int a, int b, int c, const State *s) {
    int o1 = orient(s->vertices[a][0], s->vertices[a][1],
                    s->vertices[b][0], s->vertices[b][1], px, py);
    int o2 = orient(s->vertices[b][0], s->vertices[b][1],
                    s->vertices[c][0], s->vertices[c][1], px, py);
    int o3 = orient(s->vertices[c][0], s->vertices[c][1],
                    s->vertices[a][0], s->vertices[a][1], px, py);
    return o1 >= 0 && o2 >= 0 && o3 >= 0;
}

static bool triangle_hits_box(const State *s, int tid,
                              int xmin, int ymin, int xmax, int ymax) {
    int *t = (int *)s->triangles[tid];
    for (int i = 0; i < 3; ++i) {
        int v = t[i], x = s->vertices[v][0], y = s->vertices[v][1];
        if (xmin <= x && x <= xmax && ymin <= y && y <= ymax) return true;
    }
    if (point_in_triangle(xmin, ymin, t[0], t[1], t[2], s) ||
        point_in_triangle(xmax, ymin, t[0], t[1], t[2], s) ||
        point_in_triangle(xmax, ymax, t[0], t[1], t[2], s) ||
        point_in_triangle(xmin, ymax, t[0], t[1], t[2], s)) return true;
    for (int i = 0; i < 3; ++i) {
        int edge = t[i], next = t[(i + 1) % 3];
        int ax = s->vertices[edge][0], ay = s->vertices[edge][1];
        int bx = s->vertices[next][0], by = s->vertices[next][1];
        if (segments_intersect(ax, ay, bx, by, xmin, ymin, xmax, ymin) ||
            segments_intersect(ax, ay, bx, by, xmax, ymin, xmax, ymax) ||
            segments_intersect(ax, ay, bx, by, xmax, ymax, xmin, ymax) ||
            segments_intersect(ax, ay, bx, by, xmin, ymax, xmin, ymin)) return true;
    }
    return false;
}

static void append_pair(State *s, int key, int triangle_id) {
    if (s->pair_count >= MAX_PAIRS) { s->failed = true; return; }
    s->pairs[s->pair_count][0] = key;
    s->pairs[s->pair_count][1] = triangle_id;
    ++s->pair_count;
}

static void visit(State *s, int depth, int ix, int iy, int path_code) {
    if (s->failed) return;
    int size = 8 >> depth;
    int xmin = ix * size, xmax = xmin + size;
    int ymax = 8 - iy * size, ymin = ymax - size;
    if (!stop_cell(s, xmin, ymin, xmax, ymax)) {
        if (depth >= MAX_DEPTH) { s->failed = true; return; }
        for (int q = 0; q < 4; ++q)
            visit(s, depth + 1, 2 * ix + (q & 1), 2 * iy + (q >> 1),
                  4 * path_code + q);
        return;
    }
    int key = path_code << (2 * (MAX_DEPTH - depth));
    for (int t = 0; t < s->triangle_count; ++t)
        if (triangle_hits_box(s, t, xmin, ymin, xmax, ymax)) append_pair(s, key, t);
}

static bool add_edge(State *s, int a, int b) {
    if (a > b) { int temp = a; a = b; b = temp; }
    for (int i = 0; i < s->edge_count; ++i)
        if (s->edges[i][0] == a && s->edges[i][1] == b) return true;
    if (s->edge_count >= MAX_EDGES) return false;
    s->edges[s->edge_count][0] = a;
    s->edges[s->edge_count][1] = b;
    ++s->edge_count;
    return true;
}

static bool parse(State *s, const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return false;
    if (!((input[0] == 4 && input[1] == 2) || (input[0] == 5 && input[1] == 4))) return false;
    int v = (int)input[0], t = (int)input[1];
    if (length != (size_t)(2 + 2 * v + 3 * t)) return false;
    s->vertex_count = v;
    s->triangle_count = t;
    for (int i = 0; i < 4; ++i) {
        int x = (int)input[2 + 2 * i], y = (int)input[3 + 2 * i];
        static const int corners[8] = {0,0,8,0,8,8,0,8};
        if (x != corners[2 * i] || y != corners[2 * i + 1]) return false;
        s->vertices[i][0] = x; s->vertices[i][1] = y;
    }
    if (v == 5) {
        if (input[10] != 4 || input[11] != 4) return false;
        s->vertices[4][0] = 4; s->vertices[4][1] = 4;
    }
    int start = 2 + 2 * v;
    for (int i = 0; i < t; ++i)
        for (int j = 0; j < 3; ++j) {
            int64_t id = input[start + 3 * i + j];
            if (id < 0 || id >= v) return false;
            s->triangles[i][j] = (int)id;
        }
    if (v == 4) {
        bool diag02 = s->triangles[0][0] == 0 && s->triangles[0][1] == 1 && s->triangles[0][2] == 2 &&
                      s->triangles[1][0] == 0 && s->triangles[1][1] == 2 && s->triangles[1][2] == 3;
        bool diag13 = s->triangles[0][0] == 0 && s->triangles[0][1] == 1 && s->triangles[0][2] == 3 &&
                      s->triangles[1][0] == 1 && s->triangles[1][1] == 2 && s->triangles[1][2] == 3;
        if (!diag02 && !diag13) return false;
    } else {
        static const int fan[12] = {0,1,4,1,2,4,2,3,4,3,0,4};
        for (int i = 0; i < 12; ++i)
            if (input[start + i] != fan[i]) return false;
    }
    for (int i = 0; i < t; ++i)
        if (!add_edge(s, s->triangles[i][0], s->triangles[i][1]) ||
            !add_edge(s, s->triangles[i][1], s->triangles[i][2]) ||
            !add_edge(s, s->triangles[i][2], s->triangles[i][0])) return false;
    return true;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) output[offset + i] = (uint8_t)(bits >> (8 * i));
}

int64_t star_quadtree_fat_triangulation(const int64_t *input, size_t length,
                                       uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    State state = {0};
    if (!parse(&state, input, length)) return -1;
    visit(&state, 0, 0, 0, 0);
    if (state.failed) return -1;
    size_t bytes = (size_t)(1 + 2 * state.pair_count) * 8;
    if (bytes > MAX_OUTPUT) return -1;
    if (output == NULL || capacity < bytes) return -2;
    store_i64_le(output, 0, state.pair_count);
    size_t cursor = 8;
    for (int i = 0; i < state.pair_count; ++i) {
        store_i64_le(output, cursor, state.pairs[i][0]); cursor += 8;
        store_i64_le(output, cursor, state.pairs[i][1]); cursor += 8;
    }
    return (int64_t)bytes;
}

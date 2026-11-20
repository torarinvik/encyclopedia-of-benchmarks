#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_SEGMENTS = 8, MAX_DEPTH = 8, MAX_NODES = 2048, MAX_INPUT = 35 };

typedef struct {
    int parent, quadrant, depth;
    int xmin, ymin, xmax, ymax;
    int child[4];
    int segment_count, segment_ids[MAX_SEGMENTS];
} Node;

typedef struct {
    Node nodes[MAX_NODES];
    int node_count;
    int segments[MAX_SEGMENTS][4];
} State;

static int64_t orient(int64_t ax, int64_t ay, int64_t bx, int64_t by,
                      int64_t cx, int64_t cy) {
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

static bool between(int64_t a, int64_t b, int64_t p) {
    return (a <= p && p <= b) || (b <= p && p <= a);
}

static bool on_segment(int64_t ax, int64_t ay, int64_t bx, int64_t by,
                       int64_t px, int64_t py) {
    return between(ax, bx, px) && between(ay, by, py);
}

static bool segments_intersect(int64_t ax, int64_t ay, int64_t bx, int64_t by,
                               int64_t cx, int64_t cy, int64_t dx, int64_t dy) {
    int64_t ab_c = orient(ax, ay, bx, by, cx, cy);
    int64_t ab_d = orient(ax, ay, bx, by, dx, dy);
    int64_t cd_a = orient(cx, cy, dx, dy, ax, ay);
    int64_t cd_b = orient(cx, cy, dx, dy, bx, by);
    if (((ab_c < 0 && ab_d > 0) || (ab_c > 0 && ab_d < 0)) &&
        ((cd_a < 0 && cd_b > 0) || (cd_a > 0 && cd_b < 0))) return true;
    return (ab_c == 0 && on_segment(ax, ay, bx, by, cx, cy)) ||
           (ab_d == 0 && on_segment(ax, ay, bx, by, dx, dy)) ||
           (cd_a == 0 && on_segment(cx, cy, dx, dy, ax, ay)) ||
           (cd_b == 0 && on_segment(cx, cy, dx, dy, bx, by));
}

static bool intersects_box(const State *state, int segment_id, const Node *cell) {
    int64_t x0 = 2 * (int64_t)state->segments[segment_id][0];
    int64_t y0 = 2 * (int64_t)state->segments[segment_id][1];
    int64_t x1 = 2 * (int64_t)state->segments[segment_id][2];
    int64_t y1 = 2 * (int64_t)state->segments[segment_id][3];
    int64_t lx = cell->xmin, ly = cell->ymin, hx = cell->xmax, hy = cell->ymax;
    if ((lx <= x0 && x0 <= hx && ly <= y0 && y0 <= hy) ||
        (lx <= x1 && x1 <= hx && ly <= y1 && y1 <= hy)) return true;
    return segments_intersect(x0, y0, x1, y1, lx, ly, hx, ly) ||
           segments_intersect(x0, y0, x1, y1, hx, ly, hx, hy) ||
           segments_intersect(x0, y0, x1, y1, hx, hy, lx, hy) ||
           segments_intersect(x0, y0, x1, y1, lx, hy, lx, ly);
}

static void init_node(State *state, int id, int parent, int quadrant, int depth,
                      int xmin, int ymin, int xmax, int ymax) {
    Node *node = &state->nodes[id];
    node->parent = parent; node->quadrant = quadrant; node->depth = depth;
    node->xmin = xmin; node->ymin = ymin; node->xmax = xmax; node->ymax = ymax;
    node->segment_count = 0;
    for (int q = 0; q < 4; ++q) node->child[q] = -1;
}

static bool insert_id(State *state, int node_id, int segment_id, int threshold) {
    Node *nodes = state->nodes;
    if (nodes[node_id].child[0] >= 0) {
        for (int q = 0; q < 4; ++q) {
            int child = nodes[node_id].child[q];
            if (intersects_box(state, segment_id, &nodes[child]) &&
                !insert_id(state, child, segment_id, threshold)) return false;
        }
        return true;
    }
    Node *leaf = &nodes[node_id];
    if (leaf->segment_count >= MAX_SEGMENTS) return false;
    leaf->segment_ids[leaf->segment_count++] = segment_id;
    if (leaf->segment_count <= threshold) return true;
    if (leaf->depth >= MAX_DEPTH || state->node_count + 4 > MAX_NODES) return false;

    int old_ids[MAX_SEGMENTS], old_count = leaf->segment_count;
    for (int i = 0; i < old_count; ++i) old_ids[i] = leaf->segment_ids[i];
    int base = state->node_count;
    int px0 = leaf->xmin, py0 = leaf->ymin, px1 = leaf->xmax, py1 = leaf->ymax;
    int depth = leaf->depth + 1;
    for (int q = 0; q < 4; ++q) {
        int mx = px0 + (px1 - px0) / 2, my = py0 + (py1 - py0) / 2;
        int x0 = q % 2 == 0 ? px0 : mx;
        int x1 = q % 2 == 0 ? mx : px1;
        int y0 = q < 2 ? my : py0;
        int y1 = q < 2 ? py1 : my;
        init_node(state, base + q, node_id, q, depth, x0, y0, x1, y1);
    }
    state->node_count += 4;
    nodes[node_id].segment_count = 0;
    for (int q = 0; q < 4; ++q) nodes[node_id].child[q] = base + q;
    for (int i = 0; i < old_count; ++i) {
        for (int q = 0; q < 4; ++q) {
            int child = base + q;
            if (intersects_box(state, old_ids[i], &nodes[child]) &&
                !insert_id(state, child, old_ids[i], threshold)) return false;
        }
    }
    return true;
}

static void preorder(const State *state, int node_id, int *order, int *used) {
    order[(*used)++] = node_id;
    if (state->nodes[node_id].child[0] >= 0)
        for (int q = 0; q < 4; ++q) preorder(state, state->nodes[node_id].child[q], order, used);
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t pmr_edge_quadtree(const int64_t *input, size_t length,
                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > MAX_SEGMENTS || input[1] < 1 || input[1] > MAX_SEGMENTS) return -1;
    int count = (int)input[0], threshold = (int)input[1];
    if (length != (size_t)(2 + 4 * count)) return -1;
    State state = {0};
    for (int i = 0; i < count; ++i) {
        for (int j = 0; j < 4; ++j) {
            int64_t coordinate = input[2 + 4 * i + j];
            if (coordinate < 0 || coordinate > 255) return -1;
            state.segments[i][j] = (int)coordinate;
        }
        if (state.segments[i][0] == state.segments[i][2] && state.segments[i][1] == state.segments[i][3]) return -1;
    }
    state.node_count = 1;
    init_node(&state, 0, -1, -1, 0, -1, -1, 511, 511);
    for (int i = 0; i < count; ++i) if (!insert_id(&state, 0, i, threshold)) return -1;

    int order[MAX_NODES], remap[MAX_NODES], used = 0;
    preorder(&state, 0, order, &used);
    size_t bytes = 16;
    for (int i = 0; i < used; ++i) bytes += 32 + (size_t)state.nodes[order[i]].segment_count * 8;
    if (output == NULL || capacity < bytes) return -2;
    for (int i = 0; i < used; ++i) remap[order[i]] = i;
    store_i64_le(output, 0, used);
    store_i64_le(output, 8, count);
    size_t cursor = 16;
    for (int i = 0; i < used; ++i) {
        Node *node = &state.nodes[order[i]];
        int parent = node->parent < 0 ? -1 : remap[node->parent];
        store_i64_le(output, cursor, parent); cursor += 8;
        store_i64_le(output, cursor, node->quadrant); cursor += 8;
        store_i64_le(output, cursor, node->depth); cursor += 8;
        store_i64_le(output, cursor, node->segment_count); cursor += 8;
        for (int j = 0; j < node->segment_count; ++j) {
            store_i64_le(output, cursor, node->segment_ids[j]); cursor += 8;
        }
    }
    return (int64_t)bytes;
}

module wspd;
import "math";

const int MAX_POINTS = 8;
const int MAX_NODES = 15;
const int MAX_PAIRS = 28;
const usz MAX_OUTPUT_BYTES = 456;

struct Node { int left; int right; int count; ulong mask; double cx; double cy; double radius; }
struct Context {
    long[8] x; long[8] y; Node[15] nodes;
    ulong[28] left_masks; ulong[28] right_masks;
    int next_node; int pair_count; int point_count; int separation; bool overflow;
}

fn bool point_less(Context* c, int a, int b, int axis) {
    long a0 = axis == 0 ? c->x[a] : c->y[a]; long b0 = axis == 0 ? c->x[b] : c->y[b];
    long a1 = axis == 0 ? c->y[a] : c->x[a]; long b1 = axis == 0 ? c->y[b] : c->x[b];
    return a0 < b0 || (a0 == b0 && (a1 < b1 || (a1 == b1 && a < b)));
}

fn int build_node(Context* c, ulong mask) {
    int id = c->next_node++;
    c->nodes[id].left = -1; c->nodes[id].right = -1; c->nodes[id].mask = mask;
    int[8] members = {}; int used = 0;
    long min_x = 0, max_x = 0, min_y = 0, max_y = 0;
    for (int i = 0; i < c->point_count; i++) if ((mask & ((ulong)1 << i)) != 0) {
        if (used == 0) { min_x = max_x = c->x[i]; min_y = max_y = c->y[i]; }
        else {
            if (c->x[i] < min_x) min_x = c->x[i]; if (c->x[i] > max_x) max_x = c->x[i];
            if (c->y[i] < min_y) min_y = c->y[i]; if (c->y[i] > max_y) max_y = c->y[i];
        }
        members[used++] = i;
    }
    c->nodes[id].count = used;
    c->nodes[id].cx = ((double)min_x + (double)max_x) / 2.0;
    c->nodes[id].cy = ((double)min_y + (double)max_y) / 2.0;
    double hx = ((double)max_x - (double)min_x) / 2.0;
    double hy = ((double)max_y - (double)min_y) / 2.0;
    c->nodes[id].radius = math.sqrt(hx * hx + hy * hy);
    if (used == 1) return id;
    int axis = max_x - min_x >= max_y - min_y ? 0 : 1;
    for (int i = 1; i < used; i++) {
        int value = members[i], j = i;
        while (j > 0 && point_less(c, value, members[j - 1], axis)) { members[j] = members[j - 1]; j--; }
        members[j] = value;
    }
    ulong left_mask = 0, right_mask = 0;
    int middle = used / 2;
    for (int i = 0; i < used; i++) if (i < middle) left_mask |= (ulong)1 << members[i]; else right_mask |= (ulong)1 << members[i];
    int left = build_node(c, left_mask), right = build_node(c, right_mask);
    c->nodes[id].left = left; c->nodes[id].right = right;
    return id;
}

fn bool well_separated(Context* c, int a, int b) {
    Node x = c->nodes[a], y = c->nodes[b];
    double radius = x.radius > y.radius ? x.radius : y.radius;
    double dx = x.cx - y.cx, dy = x.cy - y.cy;
    return math.sqrt(dx * dx + dy * dy) - 2.0 * radius > (double)c->separation * radius;
}
fn void cross_nodes(Context* c, int a, int b) {
    if (c->overflow) return;
    if (well_separated(c, a, b)) {
        if (c->pair_count >= MAX_PAIRS) { c->overflow = true; return; }
        c->left_masks[c->pair_count] = c->nodes[a].mask; c->right_masks[c->pair_count] = c->nodes[b].mask; c->pair_count++;
        return;
    }
    if (c->nodes[a].radius > c->nodes[b].radius) { cross_nodes(c, c->nodes[a].left, b); cross_nodes(c, c->nodes[a].right, b); }
    else { cross_nodes(c, a, c->nodes[b].left); cross_nodes(c, a, c->nodes[b].right); }
}
fn void visit_node(Context* c, int id) {
    int left = c->nodes[id].left, right = c->nodes[id].right;
    if (left < 0) return;
    visit_node(c, left); visit_node(c, right); cross_nodes(c, left, right);
}
fn void put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz i = 0; i < 8; i++) { output[offset + i] = (char)(bits & 255); bits >>= 8; }
}

fn long wspd(long* values, usz length, char* output, usz capacity) @export("wspd") {
    if (values == null || length < 4 || length > 18 || values[0] < 1 || values[0] > MAX_POINTS || values[1] < 1 || values[1] > 8 || length != 2 + 2 * (usz)values[0]) return -1;
    Context c = {};
    c.point_count = (int)values[0]; c.separation = (int)values[1];
    for (int i = 0; i < c.point_count; i++) {
        long x = values[2 + 2 * i], y = values[3 + 2 * i];
        if (x < -1000 || x > 1000 || y < -1000 || y > 1000) return -1;
        for (int j = 0; j < i; j++) if (c.x[j] == x && c.y[j] == y) return -1;
        c.x[i] = x; c.y[i] = y;
    }
    ulong all = ((ulong)1 << c.point_count) - 1;
    visit_node(&c, build_node(&c, all));
    if (c.overflow) return -2;
    usz required = 8 + 16 * (usz)c.pair_count;
    char[456] staged = {};
    put_i64(staged, 0, c.pair_count);
    for (int i = 0; i < c.pair_count; i++) {
        put_i64(staged, 8 + 16 * (usz)i, (long)c.left_masks[i]);
        put_i64(staged, 16 + 16 * (usz)i, (long)c.right_masks[i]);
    }
    if (output == null || capacity < required) return -2;
    for (usz i = 0; i < required; i++) output[i] = staged[i];
    return (long)required;
}

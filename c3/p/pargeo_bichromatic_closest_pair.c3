module pargeo_bichromatic_closest_pair;

const int MAX_POINTS = 8;
const int MAX_NODES = 15;
const int LEAF_SIZE = 2;
const long I64_MAX = 9223372036854775807;

struct Point { long x; long y; }
struct Node { int left; int right; int start; int count; long min_x; long min_y; long max_x; long max_y; }
struct Tree { Point[8] points; int[8] order; int[8] scratch; Node[15] nodes; int used; }

fn int build(Tree* tree, int start, int count) {
    int id = tree.used++;
    Point first = tree.points[tree.order[start]];
    Node node = { -1, -1, start, count, first.x, first.y, first.x, first.y };
    for (int i = 1; i < count; i++) {
        Point p = tree.points[tree.order[start + i]];
        if (p.x < node.min_x) node.min_x = p.x; if (p.x > node.max_x) node.max_x = p.x;
        if (p.y < node.min_y) node.min_y = p.y; if (p.y > node.max_y) node.max_y = p.y;
    }
    if (count <= LEAF_SIZE) { tree.nodes[id] = node; return id; }
    bool axis_x = node.max_x - node.min_x > node.max_y - node.min_y;
    long midpoint_twice = if axis_x then node.min_x + node.max_x else node.min_y + node.max_y;
    int left_count = 0;
    for (int i = 0; i < count; i++) {
        Point p = tree.points[tree.order[start + i]];
        long coordinate = if axis_x then p.x else p.y;
        if (2 * coordinate < midpoint_twice) left_count++;
    }
    if (left_count == 0 || left_count == count) {
        left_count = (count + 1) / 2;
        for (int i = 0; i < count; i++) tree.scratch[i] = tree.order[start + i];
    } else {
        int l = 0, r = left_count;
        for (int i = 0; i < count; i++) {
            int index = tree.order[start + i]; Point p = tree.points[index];
            long coordinate = if axis_x then p.x else p.y;
            if (2 * coordinate < midpoint_twice) { tree.scratch[l] = index; l++; }
            else { tree.scratch[r] = index; r++; }
        }
    }
    for (int i = 0; i < count; i++) tree.order[start + i] = tree.scratch[i];
    int left = build(tree, start, left_count);
    int right = build(tree, start + left_count, count - left_count);
    node.left = left; node.right = right; node.count = 0; tree.nodes[id] = node;
    return id;
}

fn long box_distance(Node a, Node b) {
    long dx = 0, dy = 0;
    if (a.max_x < b.min_x) dx = b.min_x - a.max_x; else if (b.max_x < a.min_x) dx = a.min_x - b.max_x;
    if (a.max_y < b.min_y) dy = b.min_y - a.max_y; else if (b.max_y < a.min_y) dy = a.min_y - b.max_y;
    return dx * dx + dy * dy;
}
fn void search(Tree* a, int ai, Tree* b, int bi, long* best) {
    Node na = a.nodes[ai], nb = b.nodes[bi];
    if (box_distance(na, nb) > *best) return;
    bool al = na.left < 0, bl = nb.left < 0;
    if (al && bl) {
        for (int i = 0; i < na.count; i++) for (int j = 0; j < nb.count; j++) {
            Point p = a.points[a.order[na.start + i]], q = b.points[b.order[nb.start + j]];
            long dx = p.x - q.x, dy = p.y - q.y, d = dx * dx + dy * dy;
            if (d < *best) *best = d;
        }
    } else if (al) {
        int l = nb.left, r = nb.right;
        if (box_distance(na, b.nodes[l]) < box_distance(na, b.nodes[r])) { search(a, ai, b, l, best); search(a, ai, b, r, best); }
        else { search(a, ai, b, r, best); search(a, ai, b, l, best); }
    } else if (bl) {
        int l = na.left, r = na.right;
        if (box_distance(nb, a.nodes[l]) < box_distance(nb, a.nodes[r])) { search(a, l, b, bi, best); search(a, r, b, bi, best); }
        else { search(a, r, b, bi, best); search(a, l, b, bi, best); }
    } else {
        int[4][2] pairs = { {na.left, nb.left}, {na.left, nb.right}, {na.right, nb.left}, {na.right, nb.right} };
        long[4] distances;
        for (int i = 0; i < 4; i++) distances[i] = box_distance(a.nodes[pairs[i][0]], b.nodes[pairs[i][1]]);
        for (int i = 1; i < 4; i++) {
            int p0 = pairs[i][0], p1 = pairs[i][1]; long d = distances[i]; int j = i;
            while (j > 0 && d < distances[j - 1]) { pairs[j][0] = pairs[j - 1][0]; pairs[j][1] = pairs[j - 1][1]; distances[j] = distances[j - 1]; j--; }
            pairs[j][0] = p0; pairs[j][1] = p1; distances[j] = d;
        }
        for (int i = 0; i < 4; i++) search(a, pairs[i][0], b, pairs[i][1], best);
    }
}
fn void write_i64(uchar* output, long value) {
    ulong bits = (ulong)value;
    for (int i = 0; i < 8; i++) output[i] = (uchar)(bits >> (8 * i));
}

// Clean-room bounded ParGeo profile; see package LICENSE.txt for the complete MIT notice.
fn long pargeo_bichromatic_closest_pair(long* input, usz input_length, uchar* output, usz output_capacity)
    @export("pargeo_bichromatic_closest_pair") {
    if (input == null || input_length < 10 || input_length > 34) return -1;
    if (input[0] < 2 || input[0] > MAX_POINTS || input[1] < 2 || input[1] > MAX_POINTS) return -1;
    int na = (int)input[0], nb = (int)input[1];
    if (input_length != (usz)(2 + 2 * (na + nb))) return -1;
    for (usz i = 2; i < input_length; i++) if (input[i] < -1000000 || input[i] > 1000000) return -1;
    if (output == null || output_capacity < 8) return -2;
    Tree a = {}, b = {};
    for (int i = 0; i < na; i++) { a.points[i] = { input[2 + 2 * i], input[3 + 2 * i] }; a.order[i] = i; }
    int offset = 2 + 2 * na;
    for (int i = 0; i < nb; i++) { b.points[i] = { input[offset + 2 * i], input[offset + 2 * i + 1] }; b.order[i] = i; }
    int ra = build(&a, 0, na), rb = build(&b, 0, nb);
    long best = I64_MAX; search(&a, ra, &b, rb, &best); write_i64(output, best); return 8;
}

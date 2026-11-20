module star_quadtree_fat_triangulation;

const usz MAX_INPUT = 25;
const int MAX_DEPTH = 2;

struct State {
    int[5][2] vertices;
    int[4][3] triangles;
    int[8][2] edges;
    int[64][2] pairs;
    int vertex_count, triangle_count, edge_count, pair_count;
    bool failed;
}

fn int orient(int ax, int ay, int bx, int by, int cx, int cy) {
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

fn bool between(int a, int b, int p) { return (a <= p && p <= b) || (b <= p && p <= a); }

fn bool on_segment(int ax, int ay, int bx, int by, int px, int py) {
    return between(ax, bx, px) && between(ay, by, py);
}

fn bool intersects(int ax, int ay, int bx, int by, int cx, int cy, int dx, int dy) {
    int o1 = orient(ax, ay, bx, by, cx, cy), o2 = orient(ax, ay, bx, by, dx, dy);
    int o3 = orient(cx, cy, dx, dy, ax, ay), o4 = orient(cx, cy, dx, dy, bx, by);
    if (((o1 < 0 && o2 > 0) || (o1 > 0 && o2 < 0)) &&
        ((o3 < 0 && o4 > 0) || (o3 > 0 && o4 < 0))) return true;
    return (o1 == 0 && on_segment(ax, ay, bx, by, cx, cy)) ||
           (o2 == 0 && on_segment(ax, ay, bx, by, dx, dy)) ||
           (o3 == 0 && on_segment(cx, cy, dx, dy, ax, ay)) ||
           (o4 == 0 && on_segment(cx, cy, dx, dy, bx, by));
}

fn bool edge_hits_box(State* s, int edge_id, int xmin, int ymin, int xmax, int ymax) {
    int a = s.edges[edge_id][0], b = s.edges[edge_id][1];
    int ax = s.vertices[a][0], ay = s.vertices[a][1];
    int bx = s.vertices[b][0], by = s.vertices[b][1];
    if ((xmin <= ax && ax <= xmax && ymin <= ay && ay <= ymax) ||
        (xmin <= bx && bx <= xmax && ymin <= by && by <= ymax)) return true;
    return intersects(ax, ay, bx, by, xmin, ymin, xmax, ymin) ||
           intersects(ax, ay, bx, by, xmax, ymin, xmax, ymax) ||
           intersects(ax, ay, bx, by, xmax, ymax, xmin, ymax) ||
           intersects(ax, ay, bx, by, xmin, ymax, xmin, ymin);
}

fn bool stopping(State* s, int xmin, int ymin, int xmax, int ymax) {
    bool[8] touched = zeroed;
    int count = 0;
    for (int e = 0; e < s.edge_count; e++) {
        touched[e] = edge_hits_box(s, e, xmin, ymin, xmax, ymax);
        if (touched[e]) count++;
    }
    if (count == 0) return true;
    for (int v = 0; v < s.vertex_count; v++) {
        bool common = true;
        for (int e = 0; e < s.edge_count; e++)
            if (touched[e] && s.edges[e][0] != v && s.edges[e][1] != v) common = false;
        if (common) return true;
    }
    return false;
}

fn bool point_in_triangle(State* s, int px, int py, int a, int b, int c) {
    return orient(s.vertices[a][0], s.vertices[a][1], s.vertices[b][0], s.vertices[b][1], px, py) >= 0 &&
           orient(s.vertices[b][0], s.vertices[b][1], s.vertices[c][0], s.vertices[c][1], px, py) >= 0 &&
           orient(s.vertices[c][0], s.vertices[c][1], s.vertices[a][0], s.vertices[a][1], px, py) >= 0;
}

fn bool triangle_hits_box(State* s, int tid, int xmin, int ymin, int xmax, int ymax) {
    int a = s.triangles[tid][0], b = s.triangles[tid][1], c = s.triangles[tid][2];
    for (int k = 0; k < 3; k++) {
        int v = s.triangles[tid][k], x = s.vertices[v][0], y = s.vertices[v][1];
        if (xmin <= x && x <= xmax && ymin <= y && y <= ymax) return true;
    }
    if (point_in_triangle(s, xmin, ymin, a, b, c) || point_in_triangle(s, xmax, ymin, a, b, c) ||
        point_in_triangle(s, xmax, ymax, a, b, c) || point_in_triangle(s, xmin, ymax, a, b, c)) return true;
    for (int k = 0; k < 3; k++) {
        int u = s.triangles[tid][k], v = s.triangles[tid][(k + 1) % 3];
        int ax = s.vertices[u][0], ay = s.vertices[u][1], bx = s.vertices[v][0], by = s.vertices[v][1];
        if (intersects(ax, ay, bx, by, xmin, ymin, xmax, ymin) ||
            intersects(ax, ay, bx, by, xmax, ymin, xmax, ymax) ||
            intersects(ax, ay, bx, by, xmax, ymax, xmin, ymax) ||
            intersects(ax, ay, bx, by, xmin, ymax, xmin, ymin)) return true;
    }
    return false;
}

fn void append_pair(State* s, int key, int tid) {
    if (s.pair_count >= 64) { s.failed = true; return; }
    s.pairs[s.pair_count][0] = key; s.pairs[s.pair_count][1] = tid; s.pair_count++;
}

fn void visit(State* s, int depth, int ix, int iy, int path) {
    if (s.failed) return;
    int size = 8 >> depth, xmin = ix * size, xmax = xmin + size;
    int ymax = 8 - iy * size, ymin = ymax - size;
    if (!stopping(s, xmin, ymin, xmax, ymax)) {
        if (depth >= MAX_DEPTH) { s.failed = true; return; }
        for (int q = 0; q < 4; q++)
            visit(s, depth + 1, 2 * ix + (q & 1), 2 * iy + (q >> 1), 4 * path + q);
        return;
    }
    int key = path << (2 * (MAX_DEPTH - depth));
    for (int t = 0; t < s.triangle_count; t++)
        if (triangle_hits_box(s, t, xmin, ymin, xmax, ymax)) append_pair(s, key, t);
}

fn bool add_edge(State* s, int a, int b) {
    if (a > b) { int tmp = a; a = b; b = tmp; }
    for (int i = 0; i < s.edge_count; i++)
        if (s.edges[i][0] == a && s.edges[i][1] == b) return true;
    if (s.edge_count >= 8) return false;
    s.edges[s.edge_count][0] = a; s.edges[s.edge_count][1] = b; s.edge_count++;
    return true;
}

fn bool parse(State* s, long* input, usz length) {
    if (input == null || length < 2 || length > MAX_INPUT) return false;
    if (!((input[0] == 4 && input[1] == 2) || (input[0] == 5 && input[1] == 4))) return false;
    s.vertex_count = (int)input[0]; s.triangle_count = (int)input[1];
    if (length != (usz)(2 + 2 * s.vertex_count + 3 * s.triangle_count)) return false;
    int[8] corners = {0,0,8,0,8,8,0,8};
    for (int i = 0; i < 4; i++) {
        if (input[2 + 2 * i] != corners[2 * i] || input[3 + 2 * i] != corners[2 * i + 1]) return false;
        s.vertices[i][0] = corners[2 * i]; s.vertices[i][1] = corners[2 * i + 1];
    }
    if (s.vertex_count == 5) {
        if (input[10] != 4 || input[11] != 4) return false;
        s.vertices[4][0] = 4; s.vertices[4][1] = 4;
    }
    int start = 2 + 2 * s.vertex_count;
    for (int i = 0; i < s.triangle_count; i++) for (int j = 0; j < 3; j++) {
        long id = input[start + 3 * i + j]; if (id < 0 || id >= s.vertex_count) return false;
        s.triangles[i][j] = (int)id;
    }
    if (s.vertex_count == 4) {
        bool d02 = s.triangles[0][0] == 0 && s.triangles[0][1] == 1 && s.triangles[0][2] == 2 &&
                   s.triangles[1][0] == 0 && s.triangles[1][1] == 2 && s.triangles[1][2] == 3;
        bool d13 = s.triangles[0][0] == 0 && s.triangles[0][1] == 1 && s.triangles[0][2] == 3 &&
                   s.triangles[1][0] == 1 && s.triangles[1][1] == 2 && s.triangles[1][2] == 3;
        if (!d02 && !d13) return false;
    } else {
        int[12] fan = {0,1,4,1,2,4,2,3,4,3,0,4};
        for (int i = 0; i < 12; i++) if (input[start + i] != fan[i]) return false;
    }
    for (int i = 0; i < s.triangle_count; i++)
        if (!add_edge(s, s.triangles[i][0], s.triangles[i][1]) ||
            !add_edge(s, s.triangles[i][1], s.triangles[i][2]) ||
            !add_edge(s, s.triangles[i][2], s.triangles[i][0])) return false;
    return true;
}

fn void store_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long star_quadtree_fat_triangulation(long* input, usz length, char* output, usz capacity)
    @export("star_quadtree_fat_triangulation") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    State s = zeroed;
    if (!parse(&s, input, length)) return -1;
    visit(&s, 0, 0, 0, 0);
    if (s.failed) return -1;
    usz bytes = (usz)(1 + 2 * s.pair_count) * 8;
    if (output == null || capacity < bytes) return -2;
    store_le(output, 0, s.pair_count);
    usz cursor = 8;
    for (int i = 0; i < s.pair_count; i++) {
        store_le(output, cursor, s.pairs[i][0]); cursor += 8;
        store_le(output, cursor, s.pairs[i][1]); cursor += 8;
    }
    return (long)bytes;
}

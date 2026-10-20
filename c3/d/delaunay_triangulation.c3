module delaunay_triangulation;

const int MAX_POINTS = 8;
const int MAX_VERTICES = 11;
const int MAX_WORK_TRIANGLES = 17;
const int MAX_WORK_EDGES = 51;
const int MAX_TRIANGLES = 11;
const usz MAX_OUTPUT_BYTES = 272;
const double CIRCUMCIRCLE_EPSILON = 1e-4;

struct Point { double x; double y; }
struct Edge { int a; int b; }
struct Triangle { int a; int b; int c; double cx; double cy; double radius_squared; }

fn long orient(long ax, long ay, long bx, long by, long cx, long cy) {
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}
fn long incircle(long ax, long ay, long bx, long by, long cx, long cy, long dx, long dy) {
    long x1 = ax - dx, y1 = ay - dy, x2 = bx - dx, y2 = by - dy, x3 = cx - dx, y3 = cy - dy;
    long q1 = x1 * x1 + y1 * y1, q2 = x2 * x2 + y2 * y2, q3 = x3 * x3 + y3 * y3;
    return q1 * (x2 * y3 - y2 * x3) - q2 * (x1 * y3 - y1 * x3) + q3 * (x1 * y2 - y1 * x2);
}
fn bool same_edge(Edge a, Edge b) { return (a.a == b.a && a.b == b.b) || (a.a == b.b && a.b == b.a); }

fn Triangle make_triangle(Point* points, int a, int b, int c) {
    Point p0 = points[a], p1 = points[b], p2 = points[c];
    double ax = p1.x - p0.x, ay = p1.y - p0.y, bx = p2.x - p0.x, by = p2.y - p0.y;
    double m = p1.x * p1.x - p0.x * p0.x + p1.y * p1.y - p0.y * p0.y;
    double u = p2.x * p2.x - p0.x * p0.x + p2.y * p2.y - p0.y * p0.y;
    double scale = 1.0 / (2.0 * (ax * by - ay * bx));
    double cx = ((p2.y - p0.y) * m + (p0.y - p1.y) * u) * scale;
    double cy = ((p0.x - p2.x) * m + (p1.x - p0.x) * u) * scale;
    double dx = p0.x - cx, dy = p0.y - cy;
    return {a, b, c, cx, cy, dx * dx + dy * dy};
}
fn void sort_indices(int* a, int* b, int* c) {
    if (*a > *b) { int t = *a; *a = *b; *b = t; }
    if (*b > *c) { int t = *b; *b = *c; *c = t; }
    if (*a > *b) { int t = *a; *a = *b; *b = t; }
}
fn bool triangle_less(Triangle a, Triangle b) {
    if (a.a != b.a) return a.a < b.a;
    if (a.b != b.b) return a.b < b.b;
    return a.c < b.c;
}
fn void put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz i = 0; i < 8; i++) { output[offset + i] = (char)(bits & 255); bits >>= 8; }
}

fn long delaunay_triangulation(long* values, usz length, char* output, usz capacity) @export("delaunay_triangulation") {
    if (values == null || length < 7 || length > 17 || values[0] < 3 || values[0] > MAX_POINTS || length != 1 + 2 * (usz)values[0]) return -1;
    int n = (int)values[0];
    long[8] ix = {}; long[8] iy = {};
    Point[11] points = {};
    long min_x = 0, max_x = 0, min_y = 0, max_y = 0;
    for (int i = 0; i < n; i++) {
        long x = values[1 + 2 * i], y = values[2 + 2 * i];
        if (x < -10 || x > 10 || y < -10 || y > 10) return -1;
        for (int j = 0; j < i; j++) if (ix[j] == x && iy[j] == y) return -1;
        ix[i] = x; iy[i] = y; points[i] = {(double)x, (double)y};
        if (i == 0) { min_x = max_x = x; min_y = max_y = y; }
        else {
            if (x < min_x) min_x = x; if (x > max_x) max_x = x;
            if (y < min_y) min_y = y; if (y > max_y) max_y = y;
        }
    }
    for (int a = 0; a < n; a++) for (int b = a + 1; b < n; b++) for (int c = b + 1; c < n; c++)
        if (orient(ix[a], iy[a], ix[b], iy[b], ix[c], iy[c]) == 0) return -1;
    for (int a = 0; a < n; a++) for (int b = a + 1; b < n; b++) for (int c = b + 1; c < n; c++) for (int d = c + 1; d < n; d++)
        if (incircle(ix[a], iy[a], ix[b], iy[b], ix[c], iy[c], ix[d], iy[d]) == 0) return -1;

    long dx = max_x - min_x, dy = max_y - min_y;
    long dmax = dx > dy ? dx : dy;
    double midx = ((double)min_x + (double)max_x) / 2.0;
    double midy = ((double)min_y + (double)max_y) / 2.0;
    int s0 = n, s1 = n + 1, s2 = n + 2;
    points[s0] = {midx - 20.0 * (double)dmax, midy - (double)dmax};
    points[s1] = {midx, midy + 20.0 * (double)dmax};
    points[s2] = {midx + 20.0 * (double)dmax, midy - (double)dmax};
    for (int a = 0; a < n + 3; a++) for (int b = a + 1; b < n + 3; b++) for (int c = b + 1; c < n + 3; c++)
        if ((points[b].x - points[a].x) * (points[c].y - points[a].y) - (points[b].y - points[a].y) * (points[c].x - points[a].x) == 0.0) return -1;

    Triangle[MAX_WORK_TRIANGLES] current = {}, next = {};
    Edge[MAX_WORK_EDGES] edges = {};
    int current_count = 1;
    current[0] = make_triangle(&points[0], s0, s1, s2);
    for (int p = 0; p < n; p++) {
        int edge_count = 0, next_count = 0;
        for (int i = 0; i < current_count; i++) {
            Triangle t = current[i];
            double vx = t.cx - points[p].x, vy = t.cy - points[p].y;
            if (vx * vx + vy * vy - t.radius_squared <= CIRCUMCIRCLE_EPSILON) {
                edges[edge_count++] = {t.a, t.b}; edges[edge_count++] = {t.b, t.c}; edges[edge_count++] = {t.a, t.c};
            } else { if (next_count >= MAX_WORK_TRIANGLES) return -1; next[next_count++] = t; }
        }
        bool[MAX_WORK_EDGES] remove = {};
        for (int i = 0; i < edge_count; i++) for (int j = 0; j < edge_count; j++) if (i != j && same_edge(edges[i], edges[j])) { remove[i] = true; remove[j] = true; }
        for (int i = 0; i < edge_count; i++) if (!remove[i]) {
            if (next_count >= MAX_WORK_TRIANGLES) return -1;
            next[next_count++] = make_triangle(&points[0], edges[i].a, edges[i].b, p);
        }
        for (int i = 0; i < next_count; i++) current[i] = next[i];
        current_count = next_count;
    }
    Triangle[MAX_TRIANGLES] result = {};
    int result_count = 0;
    for (int i = 0; i < current_count; i++) {
        Triangle t = current[i];
        if (t.a >= n || t.b >= n || t.c >= n) continue;
        if (result_count >= MAX_TRIANGLES) return -1;
        sort_indices(&t.a, &t.b, &t.c);
        int j = result_count++;
        while (j > 0 && triangle_less(t, result[j - 1])) { result[j] = result[j - 1]; j--; }
        result[j] = t;
    }
    if (result_count == 0) return -1;
    char[MAX_OUTPUT_BYTES] staged = {};
    put_i64(staged, 0, result_count);
    for (int i = 0; i < result_count; i++) {
        put_i64(staged, 8 + 24 * (usz)i, result[i].a);
        put_i64(staged, 16 + 24 * (usz)i, result[i].b);
        put_i64(staged, 24 + 24 * (usz)i, result[i].c);
    }
    usz required = 8 + 24 * (usz)result_count;
    if (output == null || capacity < required) return -2;
    for (usz i = 0; i < required; i++) output[i] = staged[i];
    return (long)required;
}

module convex_polygon_minimax_angle_edge_insertion;

const int MIN_N = 3;
const int MAX_N = 4;
const usz MAX_LEN = 10;
const int MAX_ANGLES = 12;

struct Point { long x; long y; }
struct AngleRef { int a; int b; int c; int vertex; }
struct Triangle { int a; int b; int c; }

fn long orient(Point[MAX_N] p, int a, int b, int c) {
    return (p[b].x - p[a].x) * (p[c].y - p[a].y) - (p[b].y - p[a].y) * (p[c].x - p[a].x);
}

fn long angle_dot(Point[MAX_N] p, AngleRef angle) {
    int[3] v = {angle.a, angle.b, angle.c};
    int center = v[angle.vertex];
    int[2] endpoints = zeroed;
    int used = 0;
    for (int i = 0; i < 3; i++) {
        if (v[i] != center) { endpoints[used] = v[i]; used++; }
    }
    long ux = p[endpoints[0]].x - p[center].x;
    long uy = p[endpoints[0]].y - p[center].y;
    long vx = p[endpoints[1]].x - p[center].x;
    long vy = p[endpoints[1]].y - p[center].y;
    return ux * vx + uy * vy;
}

fn long angle_den(Point[MAX_N] p, AngleRef angle) {
    int[3] v = {angle.a, angle.b, angle.c};
    int center = v[angle.vertex];
    int[2] endpoints = zeroed;
    int used = 0;
    for (int i = 0; i < 3; i++) {
        if (v[i] != center) { endpoints[used] = v[i]; used++; }
    }
    long ux = p[endpoints[0]].x - p[center].x;
    long uy = p[endpoints[0]].y - p[center].y;
    long vx = p[endpoints[1]].x - p[center].x;
    long vy = p[endpoints[1]].y - p[center].y;
    return (ux * ux + uy * uy) * (vx * vx + vy * vy);
}

fn int angle_cmp(Point[MAX_N] p, AngleRef left, AngleRef right) {
    long d1 = angle_dot(p, left), z1 = angle_den(p, left);
    long d2 = angle_dot(p, right), z2 = angle_den(p, right);
    if (d1 == 0 || d2 == 0) {
        if (d1 == d2) return 0;
        if (d1 == 0) return if d2 > 0: 1 else: -1;
        return if d1 > 0: -1 else: 1;
    }
    if ((d1 < 0) != (d2 < 0)) return if d1 < 0: 1 else: -1;
    long lhs = d1 * d1 * z2, rhs = d2 * d2 * z1;
    if (lhs == rhs) return 0;
    if (d1 > 0) return if lhs > rhs: -1 else: 1;
    return if lhs > rhs: 1 else: -1;
}

fn AngleRef triangle_max(Point[MAX_N] p, Triangle t) {
    int[3] v = {t.a, t.b, t.c};
    for (int i = 0; i < 3; i++) for (int j = i + 1; j < 3; j++) {
        if (v[i] > v[j]) { int temp = v[i]; v[i] = v[j]; v[j] = temp; }
    }
    AngleRef best = AngleRef{v[0], v[1], v[2], 0};
    for (int i = 1; i < 3; i++) {
        AngleRef candidate = AngleRef{v[0], v[1], v[2], i};
        if (angle_cmp(p, candidate, best) > 0) best = candidate;
    }
    return best;
}

fn AngleRef triangulation_max(Point[MAX_N] p, Triangle[] triangles, int count) {
    AngleRef best = triangle_max(p, triangles[0]);
    for (int i = 1; i < count; i++) {
        AngleRef candidate = triangle_max(p, triangles[i]);
        if (angle_cmp(p, candidate, best) > 0) best = candidate;
    }
    return best;
}

fn int angle_rank(Point[MAX_N] p, int n, AngleRef target) {
    AngleRef[MAX_ANGLES] distinct_lower = zeroed;
    int distinct_count = 0;
    for (int a = 0; a < n; a++) for (int b = a + 1; b < n; b++) for (int c = b + 1; c < n; c++) {
        for (int vertex = 0; vertex < 3; vertex++) {
            AngleRef candidate = AngleRef{a, b, c, vertex};
            if (angle_cmp(p, candidate, target) >= 0) continue;
            bool seen = false;
            for (int i = 0; i < distinct_count; i++) if (angle_cmp(p, candidate, distinct_lower[i]) == 0) seen = true;
            if (!seen) { distinct_lower[distinct_count] = candidate; distinct_count++; }
        }
    }
    return distinct_count + 1;
}

fn bool proper_crossing(Point[MAX_N] p, int a, int b, int c, int d) {
    return orient(p, a, b, c) * orient(p, a, b, d) < 0 && orient(p, c, d, a) * orient(p, c, d, b) < 0;
}

fn long convex_polygon_minimax_angle_edge_insertion(long* input, usz length)
    @export("convex_polygon_minimax_angle_edge_insertion") {
    if (input == null || length < 1 || length > MAX_LEN) return -1;
    if (input[0] < MIN_N || input[0] > MAX_N) return -1;
    int n = (int)input[0];
    if (length != 1 + 2 * n) return -1;
    Point[MAX_N] p = zeroed;
    for (int i = 0; i < n; i++) {
        p[i] = Point{input[1 + 2 * i], input[2 + 2 * i]};
        if (p[i].x < -16 || p[i].x > 16 || p[i].y < -16 || p[i].y > 16) return -1;
        for (int j = 0; j < i; j++) if (p[i].x == p[j].x && p[i].y == p[j].y) return -1;
    }
    long area2 = 0;
    for (int i = 0; i < n; i++) {
        int next = (i + 1) % n;
        area2 += p[i].x * p[next].y - p[i].y * p[next].x;
    }
    if (area2 == 0) return -1;
    int orientation = if area2 > 0: 1 else: -1;
    for (int a = 0; a < n; a++) for (int b = a + 1; b < n; b++) for (int c = b + 1; c < n; c++)
        if (orient(p, a, b, c) == 0) return -1;
    for (int edge = 0; edge < n; edge++) {
        int next = (edge + 1) % n;
        for (int vertex = 0; vertex < n; vertex++)
            if (vertex != edge && vertex != next && orientation * orient(p, edge, next, vertex) <= 0) return -1;
    }

    Triangle[2] fan = {Triangle{0, 1, 2}, Triangle{0, 2, 3}};
    AngleRef worst = if n == 3: triangle_max(p, Triangle{0, 1, 2}) else: triangulation_max(p, fan, 2);
    if (n == 4) {
        bool accepted = false;
        for (int ti = 0; ti < 2 && !accepted; ti++) {
            int[3] vertices = {fan[ti].a, fan[ti].b, fan[ti].c};
            for (int vertex = 0; vertex < 3 && !accepted; vertex++) {
                AngleRef candidate = AngleRef{vertices[0], vertices[1], vertices[2], vertex};
                if (angle_cmp(p, candidate, worst) != 0) continue;
                int q = vertices[vertex];
                int[2] opposite = zeroed;
                int used = 0, s = -1;
                for (int i = 0; i < 3; i++) if (i != vertex) { opposite[used] = vertices[i]; used++; }
                for (int i = 0; i < 4; i++) if (i != vertices[0] && i != vertices[1] && i != vertices[2]) s = i;
                if (!proper_crossing(p, q, s, opposite[0], opposite[1])) continue;
                Triangle[2] inserted = {Triangle{q, s, opposite[0]}, Triangle{q, s, opposite[1]}};
                AngleRef replacement = triangulation_max(p, inserted, 2);
                if (angle_cmp(p, replacement, worst) < 0) { worst = replacement; accepted = true; }
            }
        }
    }
    return angle_rank(p, n, worst);
}

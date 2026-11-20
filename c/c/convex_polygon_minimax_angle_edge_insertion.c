#include <stddef.h>
#include <stdint.h>

enum { MIN_N = 3, MAX_N = 4, MAX_LEN = 10, MAX_ANGLES = 12 };

typedef struct { int64_t x, y; } Point;
typedef struct { int a, b, c, vertex; } AngleRef;
typedef struct { int a, b, c; } Triangle;

static int64_t orient(const Point p[MAX_N], int a, int b, int c) {
    return (p[b].x - p[a].x) * (p[c].y - p[a].y)
         - (p[b].y - p[a].y) * (p[c].x - p[a].x);
}

static int angle_parts(const Point p[MAX_N], AngleRef angle, int64_t *dot, int64_t *den) {
    const int v[3] = { angle.a, angle.b, angle.c };
    const int center = v[angle.vertex];
    int endpoints[2], used = 0;
    for (int i = 0; i < 3; ++i) if (v[i] != center) endpoints[used++] = v[i];
    const int64_t ux = p[endpoints[0]].x - p[center].x;
    const int64_t uy = p[endpoints[0]].y - p[center].y;
    const int64_t vx = p[endpoints[1]].x - p[center].x;
    const int64_t vy = p[endpoints[1]].y - p[center].y;
    *dot = ux * vx + uy * vy;
    *den = (ux * ux + uy * uy) * (vx * vx + vy * vy);
    return 0;
}

/* Return -1, 0, 1 according as left is a smaller, equal, or larger angle. */
static int angle_cmp(const Point p[MAX_N], AngleRef left, AngleRef right) {
    int64_t d1, z1, d2, z2;
    angle_parts(p, left, &d1, &z1);
    angle_parts(p, right, &d2, &z2);
    if (d1 == 0 || d2 == 0) {
        if (d1 == d2) return 0;
        if (d1 == 0) return d2 > 0 ? 1 : -1;
        return d1 > 0 ? -1 : 1;
    }
    if ((d1 < 0) != (d2 < 0)) return d1 < 0 ? 1 : -1;
    const int64_t lhs = d1 * d1 * z2;
    const int64_t rhs = d2 * d2 * z1;
    if (lhs == rhs) return 0;
    if (d1 > 0) return lhs > rhs ? -1 : 1;
    return lhs > rhs ? 1 : -1;
}

static AngleRef triangle_max(const Point p[MAX_N], Triangle t) {
    int v[3] = { t.a, t.b, t.c };
    if (v[0] > v[1]) { int x = v[0]; v[0] = v[1]; v[1] = x; }
    if (v[1] > v[2]) { int x = v[1]; v[1] = v[2]; v[2] = x; }
    if (v[0] > v[1]) { int x = v[0]; v[0] = v[1]; v[1] = x; }
    AngleRef best = { v[0], v[1], v[2], 0 };
    for (int i = 1; i < 3; ++i) {
        AngleRef candidate = { v[0], v[1], v[2], i };
        if (angle_cmp(p, candidate, best) > 0) best = candidate;
    }
    return best;
}

static AngleRef triangulation_max(const Point p[MAX_N], const Triangle *triangles, int count) {
    AngleRef best = triangle_max(p, triangles[0]);
    for (int i = 1; i < count; ++i) {
        AngleRef candidate = triangle_max(p, triangles[i]);
        if (angle_cmp(p, candidate, best) > 0) best = candidate;
    }
    return best;
}

static int angle_rank(const Point p[MAX_N], int n, AngleRef target) {
    AngleRef distinct_lower[MAX_ANGLES];
    int distinct_count = 0;
    for (int a = 0; a < n; ++a) for (int b = a + 1; b < n; ++b) for (int c = b + 1; c < n; ++c) {
        for (int vertex = 0; vertex < 3; ++vertex) {
            AngleRef candidate = { a, b, c, vertex };
            if (angle_cmp(p, candidate, target) >= 0) continue;
            int seen = 0;
            for (int i = 0; i < distinct_count; ++i)
                if (angle_cmp(p, candidate, distinct_lower[i]) == 0) { seen = 1; break; }
            if (!seen) distinct_lower[distinct_count++] = candidate;
        }
    }
    return distinct_count + 1;
}

static int proper_crossing(const Point p[MAX_N], int a, int b, int c, int d) {
    return orient(p, a, b, c) * orient(p, a, b, d) < 0
        && orient(p, c, d, a) * orient(p, c, d, b) < 0;
}

int64_t convex_polygon_minimax_angle_edge_insertion(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_LEN) return -1;
    if (input[0] < MIN_N || input[0] > MAX_N) return -1;
    const int n = (int)input[0];
    if (length != (size_t)(1 + 2 * n)) return -1;

    Point p[MAX_N] = {{0, 0}};
    for (int i = 0; i < n; ++i) {
        p[i].x = input[1 + 2 * i]; p[i].y = input[2 + 2 * i];
        if (p[i].x < -16 || p[i].x > 16 || p[i].y < -16 || p[i].y > 16) return -1;
        for (int j = 0; j < i; ++j) if (p[i].x == p[j].x && p[i].y == p[j].y) return -1;
    }
    int64_t area2 = 0;
    for (int i = 0; i < n; ++i) {
        int next = (i + 1) % n;
        area2 += p[i].x * p[next].y - p[i].y * p[next].x;
    }
    if (area2 == 0) return -1;
    const int orientation = area2 > 0 ? 1 : -1;
    for (int a = 0; a < n; ++a) for (int b = a + 1; b < n; ++b) for (int c = b + 1; c < n; ++c)
        if (orient(p, a, b, c) == 0) return -1;
    for (int edge = 0; edge < n; ++edge) {
        int next = (edge + 1) % n;
        for (int vertex = 0; vertex < n; ++vertex)
            if (vertex != edge && vertex != next && orientation * orient(p, edge, next, vertex) <= 0) return -1;
    }

    Triangle current[2] = {{0, 1, 2}, {0, 2, 3}};
    AngleRef worst = n == 3 ? triangle_max(p, (Triangle){0, 1, 2}) : triangulation_max(p, current, 2);
    if (n == 4) {
        int accepted = 0;
        for (int ti = 0; ti < 2 && !accepted; ++ti) {
            int vertices[3] = { current[ti].a, current[ti].b, current[ti].c };
            for (int vertex = 0; vertex < 3 && !accepted; ++vertex) {
                AngleRef candidate = { vertices[0], vertices[1], vertices[2], vertex };
                if (angle_cmp(p, candidate, worst) != 0) continue;
                const int q = vertices[vertex];
                int pr[2], used = 0, s = -1;
                for (int i = 0; i < 3; ++i) if (i != vertex) pr[used++] = vertices[i];
                for (int i = 0; i < 4; ++i) if (i != vertices[0] && i != vertices[1] && i != vertices[2]) s = i;
                if (!proper_crossing(p, q, s, pr[0], pr[1])) continue;
                Triangle inserted[2] = {{q, s, pr[0]}, {q, s, pr[1]}};
                AngleRef replacement = triangulation_max(p, inserted, 2);
                if (angle_cmp(p, replacement, worst) < 0) { worst = replacement; accepted = 1; }
            }
        }
    }
    return angle_rank(p, n, worst);
}

#include <stddef.h>
#include <stdint.h>

enum { MIN_N = 3, MAX_N = 6, MAX_LENGTH = 14, MAX_STEPS_PER_VERTEX = 4 };
typedef struct { int64_t x, y; } Point;

static int64_t orient(Point a, Point b, Point c) {
    return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);
}

static int64_t distance_squared(Point a, Point b) {
    const int64_t dx = a.x-b.x;
    const int64_t dy = a.y-b.y;
    return dx*dx+dy*dy;
}

static int diagonal_bit(int n, int a, int b) {
    if (a > b) { const int temporary = a; a = b; b = temporary; }
    int bit = 0;
    for (int left = 0; left < n; ++left) {
        for (int right = left + 2; right < n; ++right) {
            if (left == 0 && right == n - 1) continue;
            if (left == a && right == b) return bit;
            ++bit;
        }
    }
    return -1;
}

static int angle_at_least_sixty(Point p, Point q, Point r) {
    const int64_t ux = p.x-q.x, uy = p.y-q.y;
    const int64_t vx = r.x-q.x, vy = r.y-q.y;
    const int64_t dot = ux*vx+uy*vy;
    if (dot <= 0) return 1;
    const int64_t norm_u = ux*ux+uy*uy;
    const int64_t norm_v = vx*vx+vy*vy;
    return 4*dot*dot <= norm_u*norm_v;
}

static int64_t greedy_triangulation(const Point points[MAX_N], int n) {
    int next[MAX_N];
    int active_count = n;
    for (int i = 0; i < n; ++i) next[i] = (i+1)%n;
    int64_t shortest = INT64_MAX;
    int64_t diagonal_mask = 0;
    for (int i = 0; i < n; ++i) {
        const int64_t edge = distance_squared(points[i], points[(i+1)%n]);
        if (edge < shortest) shortest = edge;
    }

    int p = 0, q = next[0], r = next[q];
    int steps = 0;
    while (active_count > 3) {
        if (++steps > MAX_STEPS_PER_VERTEX*n) return -1;
        if (angle_at_least_sixty(points[p], points[q], points[r])) {
            const int64_t chord = distance_squared(points[p], points[r]);
            if (chord < shortest) shortest = chord;
            const int bit = diagonal_bit(n, p, r);
            if (bit < 0) return -1;
            diagonal_mask |= INT64_C(1) << bit;
            next[p] = r;
            --active_count;
            q = r;
            r = next[r];
        } else {
            p = q;
            q = r;
            r = next[r];
        }
    }
    return shortest * 512 + diagonal_mask;
}

int64_t convex_polygon_max_min_length_triangulation(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_LENGTH) return -1;
    if (input[0] < MIN_N || input[0] > MAX_N) return -1;
    const int n = (int)input[0];
    if (length != (size_t)(1+2*n)) return -1;

    Point points[MAX_N] = {{0, 0}};
    for (int i = 0; i < n; ++i) {
        points[i] = (Point){input[1+2*i], input[2+2*i]};
        if (points[i].x < -8 || points[i].x > 8 || points[i].y < -8 || points[i].y > 8) return -1;
        for (int j = 0; j < i; ++j)
            if (points[i].x == points[j].x && points[i].y == points[j].y) return -1;
    }
    int64_t area2 = 0;
    for (int i = 0; i < n; ++i) {
        const int next = (i+1)%n;
        area2 += points[i].x*points[next].y-points[i].y*points[next].x;
    }
    if (area2 <= 0) return -1;
    for (int a = 0; a < n; ++a) for (int b = a+1; b < n; ++b) for (int c = b+1; c < n; ++c)
        if (orient(points[a], points[b], points[c]) == 0) return -1;
    for (int edge = 0; edge < n; ++edge) {
        const int following = (edge+1)%n;
        for (int vertex = 0; vertex < n; ++vertex)
            if (vertex != edge && vertex != following && orient(points[edge], points[following], points[vertex]) <= 0) return -1;
    }
    return greedy_triangulation(points, n);
}

#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 32
#define MAX_INPUT 131
#define MAX_COORD INT64_C(1000000)

typedef struct { int64_t x, y; } point;

static int64_t cross_vec(point a, point b) { return a.x * b.y - a.y * b.x; }

static point edge_at(const point *p, size_t n, size_t i) {
    point next = p[(i + 1) % n];
    return (point){next.x - p[i].x, next.y - p[i].y};
}

static int angle_half(point v) { return (v.y > 0 || (v.y == 0 && v.x >= 0)) ? 0 : 1; }

static int angle_compare(point a, point b) {
    int ha = angle_half(a), hb = angle_half(b);
    if (ha != hb) return ha < hb ? -1 : 1;
    int64_t cross = cross_vec(a, b);
    return cross > 0 ? -1 : (cross < 0 ? 1 : 0);
}

static int valid_polygon(const point *p, size_t n) {
    size_t wraps = 0;
    for (size_t i = 0; i < n; ++i) {
        point a = edge_at(p, n, i), b = edge_at(p, n, (i + 1) % n);
        if (a.x == 0 && a.y == 0) return 0;
        if (cross_vec(a, b) <= 0) return 0;
        if (angle_compare(b, a) < 0) ++wraps;
    }
    return wraps == 1;
}

static void rotate_lowest(point *p, size_t n) {
    size_t first = 0;
    for (size_t i = 1; i < n; ++i)
        if (p[i].y < p[first].y || (p[i].y == p[first].y && p[i].x < p[first].x)) first = i;
    point tmp[MAX_VERTICES];
    for (size_t i = 0; i < n; ++i) tmp[i] = p[(first + i) % n];
    for (size_t i = 0; i < n; ++i) p[i] = tmp[i];
}

static void put_i64(uint8_t *out, size_t *offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[(*offset)++] = (uint8_t)(bits >> (8 * b));
}

int64_t minkowski_sum_convex_polygons(const int64_t *v, size_t n,
        uint8_t *out, size_t cap) {
    if (!v || n < 14 || n > MAX_INPUT) return -1;
    if (v[0] < 3 || v[0] > MAX_VERTICES || v[1] < 3 || v[1] > MAX_VERTICES) return -1;
    size_t pn = (size_t)v[0], qn = (size_t)v[1];
    if (n != 2 + 2 * pn + 2 * qn) return -1;
    point p[MAX_VERTICES], q[MAX_VERTICES], sum[2 * MAX_VERTICES];
    size_t at = 2;
    for (size_t i = 0; i < pn; ++i) {
        p[i] = (point){v[at], v[at + 1]}; at += 2;
        if (p[i].x < -MAX_COORD || p[i].x > MAX_COORD || p[i].y < -MAX_COORD || p[i].y > MAX_COORD) return -1;
    }
    for (size_t i = 0; i < qn; ++i) {
        q[i] = (point){v[at], v[at + 1]}; at += 2;
        if (q[i].x < -MAX_COORD || q[i].x > MAX_COORD || q[i].y < -MAX_COORD || q[i].y > MAX_COORD) return -1;
    }
    if (!valid_polygon(p, pn) || !valid_polygon(q, qn)) return -1;
    rotate_lowest(p, pn); rotate_lowest(q, qn);
    size_t i = 0, j = 0, count = 0;
    while (i < pn || j < qn) {
        sum[count++] = (point){p[i % pn].x + q[j % qn].x, p[i % pn].y + q[j % qn].y};
        if (i == pn) { ++j; continue; }
        if (j == qn) { ++i; continue; }
        int order = angle_compare(edge_at(p, pn, i), edge_at(q, qn, j));
        if (order <= 0) ++i;
        if (order >= 0) ++j;
    }
    size_t needed = (1 + 2 * count) * 8;
    if (needed > cap || !out) return -2;
    size_t offset = 0;
    put_i64(out, &offset, (int64_t)count);
    for (size_t k = 0; k < count; ++k) { put_i64(out, &offset, sum[k].x); put_i64(out, &offset, sum[k].y); }
    return (int64_t)needed;
}

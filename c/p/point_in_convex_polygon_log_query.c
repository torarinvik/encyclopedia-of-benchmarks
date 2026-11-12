#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 32
#define MAX_QUERIES 32
#define MAX_INPUT 131
#define MAX_COORD INT64_C(1000000)

typedef struct { int64_t x, y; } point;

static point subtract(point a, point b) { return (point){a.x - b.x, a.y - b.y}; }
static int64_t cross(point a, point b) { return a.x * b.y - a.y * b.x; }
static int on_segment(point a, point b, point p) {
    point edge = subtract(b, a), rel = subtract(p, a);
    return cross(edge, rel) == 0 &&
        (a.x < b.x ? (p.x >= a.x && p.x <= b.x) : (p.x >= b.x && p.x <= a.x)) &&
        (a.y < b.y ? (p.y >= a.y && p.y <= b.y) : (p.y >= b.y && p.y <= a.y));
}
static int valid_polygon(const point *p, size_t n) {
    for (size_t i = 0; i < n; ++i) {
        size_t next = (i + 1) % n;
        if (p[i].x == p[next].x && p[i].y == p[next].y) return 0;
        point edge = subtract(p[next], p[i]);
        for (size_t j = 0; j < n; ++j) {
            if (j == i || j == next) continue;
            if (cross(edge, subtract(p[j], p[i])) <= 0) return 0;
        }
        for (size_t j = i + 1; j < n; ++j)
            if (p[i].x == p[j].x && p[i].y == p[j].y) return 0;
    }
    return 1;
}
static int contains_fan(const point *fan, size_t m, point query) {
    point origin = {0, 0};
    int64_t first = cross(fan[0], query), last = cross(fan[m - 1], query);
    if (first < 0 || last > 0) return 0;
    if (first == 0) return on_segment(origin, fan[0], query);
    if (last == 0) return on_segment(origin, fan[m - 1], query);
    size_t lo = 0, hi = m;
    while (hi - lo > 1) {
        size_t mid = (lo + hi) / 2;
        if (cross(fan[mid], query) >= 0) lo = mid; else hi = mid;
    }
    point edge = subtract(fan[lo + 1], fan[lo]);
    int64_t side = cross(edge, subtract(query, fan[lo]));
    if (side < 0) return 0;
    if (side == 0) return on_segment(fan[lo], fan[lo + 1], query);
    return 1;
}
static void put_i64(uint8_t *out, size_t *offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[(*offset)++] = (uint8_t)(bits >> (8 * b));
}

int64_t point_in_convex_polygon_log_query(const int64_t *v, size_t n, uint8_t *out, size_t cap) {
    if (!v || n < 2 || n > MAX_INPUT || v[0] < 3 || v[0] > MAX_VERTICES || v[1] < 0 || v[1] > MAX_QUERIES) return -1;
    size_t vertices = (size_t)v[0], queries = (size_t)v[1];
    if (n != 2 + 2 * vertices + 2 * queries) return -1;
    point polygon[MAX_VERTICES], fan[MAX_VERTICES], query_points[MAX_QUERIES];
    int64_t answers[MAX_QUERIES];
    size_t at = 2;
    for (size_t i = 0; i < vertices; ++i) {
        polygon[i] = (point){v[at], v[at + 1]}; at += 2;
        if (polygon[i].x < -MAX_COORD || polygon[i].x > MAX_COORD || polygon[i].y < -MAX_COORD || polygon[i].y > MAX_COORD) return -1;
    }
    if (!valid_polygon(polygon, vertices)) return -1;
    for (size_t i = 0; i < queries; ++i) {
        query_points[i] = (point){v[at], v[at + 1]}; at += 2;
        if (query_points[i].x < -MAX_COORD || query_points[i].x > MAX_COORD || query_points[i].y < -MAX_COORD || query_points[i].y > MAX_COORD) return -1;
    }
    size_t pivot = 0;
    for (size_t i = 1; i < vertices; ++i)
        if (polygon[i].x < polygon[pivot].x || (polygon[i].x == polygon[pivot].x && polygon[i].y < polygon[pivot].y)) pivot = i;
    for (size_t i = 0; i + 1 < vertices; ++i) fan[i] = subtract(polygon[(pivot + i + 1) % vertices], polygon[pivot]);
    for (size_t i = 0; i < queries; ++i) answers[i] = contains_fan(fan, vertices - 1, subtract(query_points[i], polygon[pivot]));
    size_t needed = 8 * queries;
    if (needed > cap || (needed != 0 && !out)) return -2;
    size_t offset = 0;
    for (size_t i = 0; i < queries; ++i) put_i64(out, &offset, answers[i]);
    return (int64_t)needed;
}

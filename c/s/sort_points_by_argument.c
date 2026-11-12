#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

enum { MAX_N = 64, INPUT_MAX = 1 + 2 * MAX_N };
typedef struct { int64_t x, y; } Point;

static int point_half(Point p) {
    if (p.y < 0) return 0;
    if (p.y == 0 && p.x >= 0) return 1;
    return 2;
}
static int compare_points(const void *left, const void *right) {
    const Point a = *(const Point *)left, b = *(const Point *)right;
    const int ha = point_half(a), hb = point_half(b);
    if (ha != hb) return ha < hb ? -1 : 1;
    const int64_t cross = a.x * b.y - a.y * b.x;
    if (cross != 0) return cross > 0 ? -1 : 1;
    const int64_t ra = a.x * a.x + a.y * a.y, rb = b.x * b.x + b.y * b.y;
    if (ra != rb) return ra < rb ? -1 : 1;
    if (a.x != b.x) return a.x < b.x ? -1 : 1;
    return a.y < b.y ? -1 : a.y > b.y ? 1 : 0;
}
static void store_le(uint8_t *output, size_t at, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[at + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t sort_points_by_argument(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > INPUT_MAX) return -1;
    const int64_t nr = input[0];
    if (nr < 1 || nr > MAX_N || length != 1 + 2 * (size_t)nr) return -1;
    const size_t n = (size_t)nr;
    Point points[MAX_N];
    int64_t staged[2 * MAX_N];
    for (size_t i = 0; i < n; ++i) {
        points[i].x = input[1 + 2 * i];
        points[i].y = input[2 + 2 * i];
        if (points[i].x < -1000000000 || points[i].x > 1000000000 || points[i].y < -1000000000 || points[i].y > 1000000000) return -1;
    }
    const size_t required = 16 * n;
    if (output == NULL || capacity < required) return -2;
    qsort(points, n, sizeof(Point), compare_points);
    for (size_t i = 0; i < n; ++i) { staged[2 * i] = points[i].x; staged[2 * i + 1] = points[i].y; }
    for (size_t i = 0; i < 2 * n; ++i) store_le(output, 8 * i, staged[i]);
    return (int64_t)required;
}

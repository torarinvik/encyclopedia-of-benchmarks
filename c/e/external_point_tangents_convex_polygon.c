#include <stddef.h>
#include <stdint.h>

enum { MAX_VERTICES = 32, MAX_QUERIES = 16, MAX_INPUT = 99 };
enum { MAX_COORDINATE = 1000 };

typedef struct { int64_t x, y; } point;

static point subtract(point a, point b) { return (point){a.x - b.x, a.y - b.y}; }
static int64_t cross(point a, point b) { return a.x * b.y - a.y * b.x; }

static int valid_polygon(const point *p, int n) {
    for (int i = 0; i < n; ++i) {
        int next = (i + 1) % n;
        if (p[i].x == p[next].x && p[i].y == p[next].y) return 0;
        point edge = subtract(p[next], p[i]);
        for (int j = 0; j < n; ++j)
            if (j != i && j != next && cross(edge, subtract(p[j], p[i])) <= 0) return 0;
    }
    return 1;
}

static int valid_query(const point *p, int n, point q) {
    int outside = 0;
    for (int i = 0; i < n; ++i) {
        point edge = subtract(p[(i + 1) % n], p[i]);
        int64_t side = cross(edge, subtract(q, p[i]));
        if (side == 0) return 0;
        if (side < 0) outside = 1;
    }
    return outside;
}

static int build_chain(int *chain, int n, int start, int stop) {
    int length = 0, at = start;
    for (;;) {
        chain[length++] = at;
        if (at == stop) return length;
        at = (at + 1) % n;
        if (length > n) return 0;
    }
}

static int build_layers(const point *p, int n, int *lower, int *lower_len,
                        int *upper, int *upper_len) {
    int min_x = 0, max_x = 0;
    for (int i = 1; i < n; ++i) {
        if (p[i].x < p[min_x].x) min_x = i;
        if (p[i].x > p[max_x].x) max_x = i;
    }
    int left_bottom = min_x, left_top = min_x;
    int right_bottom = max_x, right_top = max_x;
    for (int i = 0; i < n; ++i) {
        if (p[i].x == p[min_x].x) {
            if (p[i].y < p[left_bottom].y) left_bottom = i;
            if (p[i].y > p[left_top].y) left_top = i;
        }
        if (p[i].x == p[max_x].x) {
            if (p[i].y < p[right_bottom].y) right_bottom = i;
            if (p[i].y > p[right_top].y) right_top = i;
        }
    }
    *lower_len = build_chain(lower, n, left_bottom, right_bottom);
    *upper_len = build_chain(upper, n, right_top, left_top);
    return *lower_len != 0 && *upper_len != 0;
}

static int split_ascending(const point *p, const int *chain, int length, int64_t qx) {
    int lo = 0, hi = length;
    while (lo < hi) {
        int mid = lo + (hi - lo) / 2;
        if (p[chain[mid]].x < qx) lo = mid + 1;
        else hi = mid;
    }
    return lo == 0 ? 0 : lo - 1;
}

static int split_descending(const point *p, const int *chain, int length, int64_t qx) {
    int lo = 0, hi = length;
    while (lo < hi) {
        int mid = lo + (hi - lo) / 2;
        if (p[chain[mid]].x > qx) lo = mid + 1;
        else hi = mid;
    }
    return lo == 0 ? 0 : lo - 1;
}

static int tangent_search(const point *p, int n, const int *chain,
                          int lo, int hi, point q, int sign) {
    int result = lo;
    while (lo <= hi) {
        int mid = lo + (hi - lo) / 2;
        int index = chain[mid];
        point here = subtract(p[index], q);
        point next = subtract(p[(index + 1) % n], q);
        point prev = subtract(p[(index + n - 1) % n], q);
        int64_t to_next = sign * cross(here, next);
        int64_t to_prev = sign * cross(here, prev);
        if (to_next >= 0 && to_prev >= 0) return mid;
        if (to_next >= 0) { result = mid; hi = mid - 1; }
        else lo = mid + 1;
    }
    return result;
}

static int supports(const point *p, int n, int index, point q, int sign) {
    point here = subtract(p[index], q);
    point prev = subtract(p[(index + n - 1) % n], q);
    point next = subtract(p[(index + 1) % n], q);
    return sign * cross(here, prev) > 0 && sign * cross(here, next) > 0;
}

static int find_tangents(const point *p, int n, const int *lower, int lower_len,
                         const int *upper, int upper_len, point q, int *first, int *second) {
    int lower_split = split_ascending(p, lower, lower_len, q.x);
    int upper_split = split_descending(p, upper, upper_len, q.x);

    int left_a = lower[tangent_search(p, n, lower, 0, lower_split, q, -1)];
    int left_b = upper[tangent_search(p, n, upper, 0, upper_split, q, -1)];
    int right_a = lower[tangent_search(p, n, lower, lower_split, lower_len - 1, q, 1)];
    int right_b = upper[tangent_search(p, n, upper, upper_split, upper_len - 1, q, 1)];
    int left = supports(p, n, left_a, q, -1) ? left_a :
               supports(p, n, left_b, q, -1) ? left_b : -1;
    int right = supports(p, n, right_a, q, 1) ? right_a :
                supports(p, n, right_b, q, 1) ? right_b : -1;
    if (left < 0 || right < 0 || left == right) return 0;
    *first = left < right ? left : right;
    *second = left < right ? right : left;
    return 1;
}

static void put_i64(uint8_t *out, size_t *offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[(*offset)++] = (uint8_t)(bits >> (8 * b));
}

int64_t external_point_tangents_convex_polygon(const int64_t *v, size_t length,
                                                uint8_t *out, size_t capacity) {
    if (!v || length < 2 || length > MAX_INPUT || v[0] < 3 || v[0] > MAX_VERTICES ||
        v[1] < 0 || v[1] > MAX_QUERIES) return -1;
    int n = (int)v[0], q_count = (int)v[1];
    if (length != (size_t)(2 + 2 * n + 2 * q_count)) return -1;
    point polygon[MAX_VERTICES], queries[MAX_QUERIES];
    int64_t answers[2 * MAX_QUERIES];
    size_t at = 2;
    for (int i = 0; i < n; ++i) {
        polygon[i] = (point){v[at], v[at + 1]}; at += 2;
        if (polygon[i].x < -MAX_COORDINATE || polygon[i].x > MAX_COORDINATE ||
            polygon[i].y < -MAX_COORDINATE || polygon[i].y > MAX_COORDINATE) return -1;
    }
    if (!valid_polygon(polygon, n)) return -1;
    int lower[MAX_VERTICES], upper[MAX_VERTICES], lower_len, upper_len;
    if (!build_layers(polygon, n, lower, &lower_len, upper, &upper_len)) return -1;
    for (int i = 0; i < q_count; ++i) {
        queries[i] = (point){v[at], v[at + 1]}; at += 2;
        if (queries[i].x < -MAX_COORDINATE || queries[i].x > MAX_COORDINATE ||
            queries[i].y < -MAX_COORDINATE || queries[i].y > MAX_COORDINATE ||
            !valid_query(polygon, n, queries[i])) return -1;
        int first, second;
        if (!find_tangents(polygon, n, lower, lower_len, upper, upper_len,
                           queries[i], &first, &second)) return -1;
        answers[2 * i] = first;
        answers[2 * i + 1] = second;
    }
    size_t needed = 16 * (size_t)q_count;
    if (needed > capacity || !out) return -2;
    size_t offset = 0;
    for (int i = 0; i < 2 * q_count; ++i) put_i64(out, &offset, answers[i]);
    return (int64_t)needed;
}

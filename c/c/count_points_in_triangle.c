#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 24, MAX_M = 24, MAX_Q = 128, INPUT_MAX = 483 };
typedef struct { int64_t x, y; } Point;
typedef struct { int64_t x, y; } Vector;
typedef struct { int64_t a, b, c; } Query;

static int angle_half(Vector v) {
    if (v.y < 0) return 0;
    if (v.y == 0 && v.x >= 0) return 1;
    return 2;
}
static int angle_less(Vector a, Vector b) {
    const int ha = angle_half(a), hb = angle_half(b);
    if (ha != hb) return ha < hb;
    return a.x * b.y - a.y * b.x > 0;
}
static int direction_less(Vector a, Vector b) {
    if (angle_less(a, b)) return 1;
    if (angle_less(b, a)) return 0;
    const int64_t ra = a.x * a.x + a.y * a.y, rb = b.x * b.x + b.y * b.y;
    if (ra != rb) return ra < rb;
    if (a.x != b.x) return a.x < b.x;
    return a.y < b.y;
}
static void sort_vectors(Vector* values, size_t count) {
    for (size_t i = 1; i < count; ++i) {
        const Vector item = values[i];
        size_t j = i;
        while (j > 0 && direction_less(item, values[j - 1])) { values[j] = values[j - 1]; --j; }
        values[j] = item;
    }
}
static size_t ray_lower_bound(const Vector* values, size_t count, Vector ray) {
    size_t low = 0, high = count;
    while (low < high) {
        const size_t middle = low + (high - low) / 2;
        if (angle_less(values[middle], ray)) low = middle + 1; else high = middle;
    }
    return low;
}
static size_t ray_upper_bound(const Vector* values, size_t count, Vector ray) {
    size_t low = 0, high = count;
    while (low < high) {
        const size_t middle = low + (high - low) / 2;
        if (!angle_less(ray, values[middle])) low = middle + 1; else high = middle;
    }
    return low;
}
static int fenwick_prefix(const int* tree, size_t end) {
    int total = 0;
    while (end > 0) { total += tree[end]; end &= end - 1; }
    return total;
}
static int count_arc(const Vector* directions, size_t count, const int* tree, Vector start, Vector end) {
    const size_t left = ray_lower_bound(directions, count, start);
    const size_t right = ray_upper_bound(directions, count, end);
    if (!angle_less(end, start)) return fenwick_prefix(tree, right) - fenwick_prefix(tree, left);
    return fenwick_prefix(tree, count) - fenwick_prefix(tree, left) + fenwick_prefix(tree, right);
}
static int halfplane_count(size_t u, size_t v, const Point* a, const Vector directions[MAX_N][MAX_M],
                           const size_t* counts, const int fenwick[MAX_N][MAX_M + 1]) {
    const Vector edge = { a[v].x - a[u].x, a[v].y - a[u].y };
    const Vector opposite = { -edge.x, -edge.y };
    return (int)counts[u] + count_arc(directions[u], counts[u], fenwick[u], opposite, edge);
}
static void store_le(uint8_t* output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t count_points_in_triangle(const int64_t* input, size_t length, uint8_t* output, size_t capacity) {
    if (input == NULL || length < 3 || length > INPUT_MAX) return -1;
    const int64_t nr = input[0], mr = input[1], qr = input[2];
    if (nr < 1 || nr > MAX_N || mr < 1 || mr > MAX_M || qr < 1 || qr > MAX_Q) return -1;
    const size_t n = (size_t)nr, m = (size_t)mr, q = (size_t)qr;
    if (length != 3 + 2 * n + 2 * m + 3 * q) return -1;
    Point a[MAX_N], b[MAX_M];
    Query queries[MAX_Q];
    size_t cursor = 3;
    for (size_t i = 0; i < n; ++i) {
        a[i] = (Point){ input[cursor], input[cursor + 1] }; cursor += 2;
        if (a[i].x < -1000000000 || a[i].x > 1000000000 || a[i].y < -1000000000 || a[i].y > 1000000000) return -1;
    }
    for (size_t i = 0; i < m; ++i) {
        b[i] = (Point){ input[cursor], input[cursor + 1] }; cursor += 2;
        if (b[i].x < -1000000000 || b[i].x > 1000000000 || b[i].y < -1000000000 || b[i].y > 1000000000) return -1;
    }
    for (size_t i = 0; i < q; ++i) {
        const int64_t ia = input[cursor], ib = input[cursor + 1], ic = input[cursor + 2]; cursor += 3;
        if (ia < 0 || ia >= nr || ib < 0 || ib >= nr || ic < 0 || ic >= nr) return -1;
        queries[i] = (Query){ ia, ib, ic };
    }
    const size_t required = 8 * q;
    if (output == NULL || capacity < required) return -2;

    Vector directions[MAX_N][MAX_M];
    size_t direction_count[MAX_N] = {0};
    int zero_count[MAX_N] = {0};
    int fenwick[MAX_N][MAX_M + 1] = {{0}};
    for (size_t anchor = 0; anchor < n; ++anchor) {
        for (size_t j = 0; j < m; ++j) {
            Vector v = { b[j].x - a[anchor].x, b[j].y - a[anchor].y };
            if (v.x == 0 && v.y == 0) ++zero_count[anchor];
            else directions[anchor][direction_count[anchor]++] = v;
        }
        sort_vectors(directions[anchor], direction_count[anchor]);
        for (size_t i = 0; i < direction_count[anchor]; ++i) {
            for (size_t at = i + 1; at <= direction_count[anchor]; at += at & (~at + 1)) ++fenwick[anchor][at];
        }
    }

    int64_t answers[MAX_Q];
    for (size_t qi = 0; qi < q; ++qi) {
        size_t ia = (size_t)queries[qi].a, ib = (size_t)queries[qi].b, ic = (size_t)queries[qi].c;
        const int64_t orient = (a[ib].x - a[ia].x) * (a[ic].y - a[ia].y) - (a[ib].y - a[ia].y) * (a[ic].x - a[ia].x);
        if (orient == 0) { answers[qi] = 0; continue; }
        if (orient < 0) { const size_t swap = ib; ib = ic; ic = swap; }
        const int outside = halfplane_count(ia, ib, a, directions, direction_count, fenwick)
                          + halfplane_count(ib, ic, a, directions, direction_count, fenwick)
                          + halfplane_count(ic, ia, a, directions, direction_count, fenwick);
        const Vector ab_at_b = { a[ib].x - a[ia].x, a[ib].y - a[ia].y };
        const Vector bc_at_b = { a[ib].x - a[ic].x, a[ib].y - a[ic].y };
        const Vector bc_at_c = { a[ic].x - a[ib].x, a[ic].y - a[ib].y };
        const Vector ca_at_c = { a[ic].x - a[ia].x, a[ic].y - a[ia].y };
        const Vector ca_at_a = { a[ia].x - a[ic].x, a[ia].y - a[ic].y };
        const Vector ab_at_a = { a[ia].x - a[ib].x, a[ia].y - a[ib].y };
        const int pairs = zero_count[ib] + count_arc(directions[ib], direction_count[ib], fenwick[ib], bc_at_b, ab_at_b)
                        + zero_count[ic] + count_arc(directions[ic], direction_count[ic], fenwick[ic], ca_at_c, bc_at_c)
                        + zero_count[ia] + count_arc(directions[ia], direction_count[ia], fenwick[ia], ab_at_a, ca_at_a);
        answers[qi] = (int64_t)m - outside + pairs;
    }
    for (size_t i = 0; i < q; ++i) store_le(output, 8 * i, answers[i]);
    return (int64_t)required;
}

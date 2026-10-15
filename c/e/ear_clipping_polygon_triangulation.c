/* Deterministic ear clipping for simple integer polygons. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 64

static int64_t orient(const int64_t *v, size_t a, size_t b, size_t c)
{
    const int64_t abx = v[2 * b] - v[2 * a];
    const int64_t aby = v[2 * b + 1] - v[2 * a + 1];
    const int64_t acx = v[2 * c] - v[2 * a];
    const int64_t acy = v[2 * c + 1] - v[2 * a + 1];
    return abx * acy - aby * acx;
}

static bool on_segment(const int64_t *v, size_t a, size_t b, size_t p)
{
    return v[2 * p] >= (v[2 * a] < v[2 * b] ? v[2 * a] : v[2 * b]) &&
           v[2 * p] <= (v[2 * a] > v[2 * b] ? v[2 * a] : v[2 * b]) &&
           v[2 * p + 1] >= (v[2 * a + 1] < v[2 * b + 1] ? v[2 * a + 1] : v[2 * b + 1]) &&
           v[2 * p + 1] <= (v[2 * a + 1] > v[2 * b + 1] ? v[2 * a + 1] : v[2 * b + 1]);
}

static bool segments_intersect(const int64_t *v, size_t a, size_t b, size_t c, size_t d)
{
    const int64_t o1 = orient(v, a, b, c), o2 = orient(v, a, b, d);
    const int64_t o3 = orient(v, c, d, a), o4 = orient(v, c, d, b);
    if (((o1 > 0 && o2 < 0) || (o1 < 0 && o2 > 0)) &&
        ((o3 > 0 && o4 < 0) || (o3 < 0 && o4 > 0))) return true;
    return (o1 == 0 && on_segment(v, a, b, c)) ||
           (o2 == 0 && on_segment(v, a, b, d)) ||
           (o3 == 0 && on_segment(v, c, d, a)) ||
           (o4 == 0 && on_segment(v, c, d, b));
}

static bool in_triangle(const int64_t *v, size_t a, size_t b, size_t c,
                        size_t p, int winding)
{
    const int64_t ab = orient(v, a, b, p) * winding;
    const int64_t bc = orient(v, b, c, p) * winding;
    const int64_t ca = orient(v, c, a, p) * winding;
    return ab >= 0 && bc >= 0 && ca >= 0;
}

static void write_u32_le(uint8_t *out, size_t position, size_t index)
{
    const uint32_t value = (uint32_t)index;
    for (size_t byte = 0; byte < 4; ++byte)
        out[4 * position + byte] = (uint8_t)(value >> (8 * byte));
}

int64_t ear_clipping_polygon_triangulation(const int64_t *values, size_t length,
                                            uint8_t *output, size_t output_capacity)
{
    if (length % 2 != 0 || length / 2 < 3 || length / 2 > MAX_VERTICES || values == NULL) return -1;
    const size_t n = length / 2;
    int64_t area2 = 0;
    for (size_t i = 0; i < n; ++i) {
        const size_t next = (i + 1) % n;
        if (values[2 * i] < -10000 || values[2 * i] > 10000 ||
            values[2 * i + 1] < -10000 || values[2 * i + 1] > 10000) return -1;
        for (size_t j = 0; j < i; ++j)
            if (values[2 * i] == values[2 * j] && values[2 * i + 1] == values[2 * j + 1]) return -1;
        area2 += values[2 * i] * values[2 * next + 1] - values[2 * i + 1] * values[2 * next];
        if (orient(values, (i + n - 1) % n, i, next) == 0) return -1;
    }
    if (area2 == 0) return -1;
    for (size_t i = 0; i < n; ++i) {
        const size_t inext = (i + 1) % n;
        for (size_t j = i + 1; j < n; ++j) {
            const size_t jnext = (j + 1) % n;
            if (inext == j || jnext == i) continue;
            if (segments_intersect(values, i, inext, j, jnext)) return -1;
        }
    }
    if (output == NULL || output_capacity < 12 * (n - 2)) return -2;

    const int winding = area2 > 0 ? 1 : -1;
    bool live[MAX_VERTICES];
    for (size_t i = 0; i < n; ++i) live[i] = true;
    size_t live_count = n, emitted = 0;
    while (live_count > 3) {
        bool clipped = false;
        for (size_t current = 0; current < n; ++current) {
            if (!live[current]) continue;
            size_t prev = (current + n - 1) % n, next = (current + 1) % n;
            while (!live[prev]) prev = (prev + n - 1) % n;
            while (!live[next]) next = (next + 1) % n;
            if (orient(values, prev, current, next) * winding <= 0) continue;
            bool contains = false;
            for (size_t point = 0; point < n; ++point) {
                if (live[point] && point != prev && point != current && point != next &&
                    in_triangle(values, prev, current, next, point, winding)) {
                    contains = true;
                    break;
                }
            }
            if (contains) continue;
            write_u32_le(output, emitted++, prev);
            write_u32_le(output, emitted++, current);
            write_u32_le(output, emitted++, next);
            live[current] = false;
            --live_count;
            clipped = true;
            break;
        }
        if (!clipped) return -1; /* Defensive: valid simple polygons always have an ear. */
    }
    size_t first = 0;
    while (!live[first]) ++first;
    size_t second = (first + 1) % n;
    while (!live[second]) second = (second + 1) % n;
    size_t third = (second + 1) % n;
    while (!live[third]) third = (third + 1) % n;
    write_u32_le(output, emitted++, first);
    write_u32_le(output, emitted++, second);
    write_u32_le(output, emitted++, third);
    return (int64_t)(n - 2);
}

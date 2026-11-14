/* Independent maximum-area triangle draft; uncompiled and unrun. */
#include <stddef.h>
#include <stdint.h>

static int64_t cross(const int64_t *p, size_t a, size_t b, size_t c) {
    int64_t ax = p[1 + 2*a], ay = p[2 + 2*a];
    return (p[1 + 2*b] - ax) * (p[2 + 2*c] - ay)
         - (p[2 + 2*b] - ay) * (p[1 + 2*c] - ax);
}

int64_t maximum_area_triangle_convex(const int64_t *p, size_t length) {
    if (!p || !length || p[0] < 3 || p[0] > 1024) return -1;
    size_t n = (size_t)p[0];
    if (length != 1 + 2*n) return -1;
    for (size_t i = 1; i < length; ++i)
        if (p[i] < -1000000 || p[i] > 1000000) return -1;
    for (size_t i = 0; i < n; ++i) {
        size_t next = (i + 1) % n;
        for (size_t j = 0; j < n; ++j)
            if (j != i && j != next && cross(p, i, next, j) <= 0) return -1;
    }
    int64_t best = 0;
    for (size_t i = 0; i + 2 < n; ++i)
        for (size_t j = i + 1; j + 1 < n; ++j) {
            size_t lo = j + 1, hi = n - 1;
            while (lo < hi) {
                size_t mid = lo + (hi - lo) / 2;
                if (cross(p, i, j, mid) < cross(p, i, j, mid + 1)) lo = mid + 1;
                else hi = mid;
            }
            int64_t area = cross(p, i, j, lo);
            if (area > best) best = area;
        }
    return best;
}

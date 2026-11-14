/* Unverified divide-and-conquer tangent-merge hull draft. */
#include <stddef.h>
#include <stdint.h>

typedef struct { int64_t x, y; } hull_point;

static int64_t cross(hull_point a, hull_point b, hull_point c) {
    return (b.x-a.x)*(c.y-a.y) - (b.y-a.y)*(c.x-a.x);
}

/* Recursive subproblems write into disjoint slices sized to their input.
 * The retained right suffix moves left after finding the bridge. */
static size_t chain(const hull_point *points, const size_t *order, size_t lo, size_t hi,
                    int upper, size_t *out) {
    size_t n = hi-lo;
    if (n == 1) { out[0] = order[lo]; return 1; }
    size_t mid = lo+n/2, left_capacity = mid-lo;
    size_t left_n = chain(points, order, lo, mid, upper, out);
    size_t right_n = chain(points, order, mid, hi, upper, out+left_capacity);
    size_t i = left_n-1, j = 0;
    int changed = 1;
    while (changed) {
        changed = 0;
        while (i > 0) {
            int64_t sign = cross(points[out[i]], points[out[left_capacity+j]], points[out[i-1]]);
            if (!(upper ? sign > 0 : sign < 0)) break;
            --i; changed = 1;
        }
        while (j+1 < right_n) {
            int64_t sign = cross(points[out[i]], points[out[left_capacity+j]], points[out[left_capacity+j+1]]);
            if (!(upper ? sign > 0 : sign < 0)) break;
            ++j; changed = 1;
        }
    }
    size_t suffix = right_n-j;
    for (size_t k = 0; k < suffix; ++k) out[i+1+k] = out[left_capacity+j+k];
    return i+1+suffix;
}

int64_t divide_conquer_tangent_hull(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    if (!input || length < 7 || length > 66 || input[0] < 3 || input[0] > 32) return -1;
    size_t n = (size_t)input[0];
    if (length != 1+2*n) return -1;
    hull_point points[32];
    size_t order[32], scratch[32];
    for (size_t i = 0; i < n; ++i) {
        points[i] = (hull_point){input[1+2*i], input[2+2*i]};
        if (points[i].x < -1000 || points[i].x > 1000 || points[i].y < -1000 || points[i].y > 1000) return -1;
        for (size_t j = 0; j < i; ++j) if (points[j].x == points[i].x) return -1;
        order[i] = i;
    }
    for (size_t i = 0; i < n; ++i)
        for (size_t j = i+1; j < n; ++j)
            for (size_t k = j+1; k < n; ++k)
                if (cross(points[i], points[j], points[k]) == 0) return -1;
    for (size_t width = 1; width < n; width *= 2) {
        for (size_t begin = 0; begin < n; begin += 2*width) {
            size_t mid = begin+width < n ? begin+width : n;
            size_t end = begin+2*width < n ? begin+2*width : n;
            size_t left = begin, right = mid, dest = begin;
            while (left < mid && right < end)
                scratch[dest++] = points[order[right]].x < points[order[left]].x ? order[right++] : order[left++];
            while (left < mid) scratch[dest++] = order[left++];
            while (right < end) scratch[dest++] = order[right++];
        }
        for (size_t i = 0; i < n; ++i) order[i] = scratch[i];
    }
    size_t lower[32], upper[32], hull[32];
    size_t lower_n = chain(points, order, 0, n, 0, lower);
    size_t upper_n = chain(points, order, 0, n, 1, upper);
    size_t count = 0;
    for (size_t i = 0; i < lower_n; ++i) hull[count++] = lower[i];
    for (size_t i = upper_n-1; i > 1;) hull[count++] = upper[--i];
    size_t bytes = 16*count;
    if (!output || capacity < bytes) return -2;
    for (size_t i = 0; i < count; ++i) {
        uint64_t words[2] = {(uint64_t)points[hull[i]].x, (uint64_t)points[hull[i]].y};
        for (size_t axis = 0; axis < 2; ++axis)
            for (size_t b = 0; b < 8; ++b) output[16*i+8*axis+b] = (uint8_t)(words[axis] >> (8*b));
    }
    return (int64_t)bytes;
}

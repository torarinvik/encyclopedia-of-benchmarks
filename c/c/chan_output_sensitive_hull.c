/* Chan hull draft: bounded validation and grouped wrapping with tangent search.
 * This implementation has not been compiled or run. */
#include <stddef.h>
#include <stdint.h>

typedef struct { int64_t x, y; size_t id; } chan_point;

static int64_t chan_cross(chan_point a, chan_point b, chan_point c) {
    return (b.x-a.x)*(c.y-a.y) - (b.y-a.y)*(c.x-a.x);
}

static int chan_validate(const int64_t *input, size_t length, chan_point points[32], size_t *count) {
    if (!input || length < 7 || length > 66 || input[0] < 3 || input[0] > 32) return 0;
    size_t n = (size_t)input[0];
    if (length != 1 + 2*n) return 0;
    for (size_t i = 0; i < n; ++i) {
        int64_t x = input[1+2*i], y = input[2+2*i];
        if (x < -1000 || x > 1000 || y < -1000 || y > 1000) return 0;
        points[i] = (chan_point){x, y, i};
        for (size_t j = 0; j < i; ++j)
            if (points[j].x == x && points[j].y == y) return 0;
    }
    for (size_t i = 0; i < n; ++i)
        for (size_t j = i+1; j < n; ++j)
            for (size_t k = j+1; k < n; ++k)
                if (chan_cross(points[i], points[j], points[k]) == 0) return 0;
    *count = n;
    return 1;
}

static int chan_less(chan_point a, chan_point b) {
    return a.x < b.x || (a.x == b.x && a.y < b.y);
}

/* Returns the CCW subgroup hull as input indices, starting at its minimum.
 * points[begin..begin+count) is sorted using bottom-up mergesort. */
static size_t chan_group_hull(const chan_point points[32], size_t begin, size_t count,
                              size_t *output) {
    chan_point sorted[32], scratch[32], hull[64];
    for (size_t i = 0; i < count; ++i) sorted[i] = points[begin+i];
    for (size_t width = 1; width < count; width *= 2) {
        for (size_t start = 0; start < count; start += 2*width) {
            size_t middle = start+width < count ? start+width : count;
            size_t end = start+2*width < count ? start+2*width : count;
            size_t left = start, right = middle, out = start;
            while (left < middle && right < end)
                scratch[out++] = chan_less(sorted[right], sorted[left]) ? sorted[right++] : sorted[left++];
            while (left < middle) scratch[out++] = sorted[left++];
            while (right < end) scratch[out++] = sorted[right++];
        }
        for (size_t i = 0; i < count; ++i) sorted[i] = scratch[i];
    }
    if (count == 1) { output[0] = sorted[0].id; return 1; }
    size_t used = 0;
    for (size_t i = 0; i < count; ++i) {
        while (used >= 2 && chan_cross(hull[used-2], hull[used-1], sorted[i]) <= 0) --used;
        hull[used++] = sorted[i];
    }
    size_t lower = used;
    for (size_t i = count-1; i > 0;) {
        --i;
        while (used > lower && chan_cross(hull[used-2], hull[used-1], sorted[i]) <= 0) --used;
        hull[used++] = sorted[i];
    }
    --used;
    for (size_t i = 0; i < used; ++i) output[i] = hull[i].id;
    return used;
}

/* Returns a subgroup vertex ID, or SIZE_MAX when the group has no candidate.
 * A query that belongs to a group is handled by chan_wrap instead. */
typedef size_t (*chan_tangent_fn)(const chan_point points[32], const size_t *hull,
                                  size_t hull_size, size_t query_id);

/* A global extreme vertex places all other input points in one open half-plane
 * through that vertex, so orientation orders their rays without an angle wrap.
 * Around a convex subgroup hull those ordered ray angles increase on one arc
 * and decrease on the other. Locate the minimum by its neighboring signs;
 * comparing against hull[0] distinguishes the two pieces of a split arc. */
static size_t chan_external_tangent(const chan_point points[32], const size_t *hull,
                                    size_t size, size_t query_id) {
    chan_point query = points[query_id];
    if (size == 1) return hull[0];
    if (size == 2)
        return chan_cross(query, points[hull[0]], points[hull[1]]) > 0 ? hull[0] : hull[1];
    int initial_up = chan_cross(query, points[hull[0]], points[hull[1]]) > 0;
    size_t lo = 0, hi = size;
    while (lo < hi) {
        size_t middle = lo + (hi-lo)/2;
        size_t before = (middle+size-1) % size, after = (middle+1) % size;
        int less_before = chan_cross(query, points[hull[middle]], points[hull[before]]) > 0;
        int less_after = chan_cross(query, points[hull[middle]], points[hull[after]]) > 0;
        if (less_before && less_after) return hull[middle];
        int mid_up = less_after;
        int before_anchor = middle != 0 &&
            chan_cross(query, points[hull[middle]], points[hull[0]]) > 0;
        int after_anchor = middle != 0 &&
            chan_cross(query, points[hull[0]], points[hull[middle]]) > 0;
        int search_left = initial_up ? (mid_up && before_anchor)
                                     : (mid_up || after_anchor);
        if (search_left) hi = middle;
        else lo = middle + 1;
    }
    return SIZE_MAX;
}

/* Construct and wrap subgroup hulls, retrying with squared guesses when the
 * current guess does not close. Output IDs are CCW from the minimum point.
 * Return 0 if the tangent callback fails; no output is emitted here. */
static int chan_wrap(const chan_point points[32], size_t count, chan_tangent_fn tangent,
                     size_t result[32], size_t *result_count) {
    size_t first = 0;
    for (size_t i = 1; i < count; ++i)
        if (chan_less(points[i], points[first])) first = i;
    size_t guess = count < 4 ? count : 4;
    for (;;) {
        size_t hulls[32], offsets[32], sizes[32], group_of[32], position[32];
        size_t groups = 0, stored = 0;
        for (size_t begin = 0; begin < count; begin += guess) {
            size_t group_size = count-begin < guess ? count-begin : guess;
            offsets[groups] = stored;
            sizes[groups] = chan_group_hull(points, begin, group_size, hulls + stored);
            for (size_t j = 0; j < group_size; ++j) {
                group_of[begin+j] = groups;
                position[begin+j] = SIZE_MAX;
            }
            for (size_t j = 0; j < sizes[groups]; ++j)
                position[hulls[stored+j]] = j;
            stored += sizes[groups];
            ++groups;
        }
        size_t used = 1;
        result[0] = first;
        for (size_t step = 0; step < guess; ++step) {
            size_t current = result[used-1], candidate = SIZE_MAX;
            for (size_t group = 0; group < groups; ++group) {
                size_t local;
                if (group == group_of[current]) {
                    if (position[current] == SIZE_MAX) return 0;
                    local = sizes[group] == 1 ? SIZE_MAX :
                        hulls[offsets[group] + (position[current]+1) % sizes[group]];
                } else {
                    local = tangent(points, hulls + offsets[group], sizes[group], current);
                    if (local == SIZE_MAX || local >= count || group_of[local] != group) return 0;
                }
                if (local != SIZE_MAX && (candidate == SIZE_MAX ||
                        chan_cross(points[current], points[candidate], points[local]) < 0))
                    candidate = local;
            }
            if (candidate == SIZE_MAX) return 0;
            if (candidate == first) { *result_count = used; return 1; }
            if (used == count) return 0;
            result[used++] = candidate;
        }
        if (guess == count) return 0;
        guess = guess > count / guess ? count : guess*guess;
    }
}

/* The caller validates input and completes wrapping before calling this; output
 * errors therefore cannot expose a partial hull. */
static int64_t chan_emit(const chan_point points[32], const size_t *hull, size_t count,
                         uint8_t *output, size_t capacity) {
    size_t needed = 16*count;
    if (!output || capacity < needed) return -2;
    for (size_t i = 0; i < count; ++i) {
        uint64_t fields[2] = {(uint64_t)points[hull[i]].x, (uint64_t)points[hull[i]].y};
        for (size_t axis = 0; axis < 2; ++axis)
            for (size_t byte = 0; byte < 8; ++byte)
                output[16*i+8*axis+byte] = (uint8_t)(fields[axis] >> (8*byte));
    }
    return (int64_t)needed;
}

int64_t chan_output_sensitive_hull(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    chan_point points[32];
    size_t count, hull[32], hull_count;
    if (!chan_validate(input, length, points, &count)) return -1;
    if (!chan_wrap(points, count, chan_external_tangent, hull, &hull_count)) return -1;
    return chan_emit(points, hull, hull_count, output, capacity);
}

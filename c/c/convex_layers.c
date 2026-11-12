#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 64
#define COORD_LIMIT INT64_C(1000000)

typedef struct { int64_t x, y; } point_t;

static int64_t cross(point_t a, point_t b, point_t c) {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

static int before(point_t left, point_t right) {
    return left.x < right.x || (left.x == right.x && left.y < right.y);
}

static void sort_points(point_t *points, size_t count) {
    for (size_t i = 1; i < count; ++i) {
        const point_t key = points[i];
        size_t j = i;
        while (j > 0 && before(key, points[j - 1])) {
            points[j] = points[j - 1];
            --j;
        }
        points[j] = key;
    }
}

static int on_segment(point_t point, point_t a, point_t b) {
    return cross(a, b, point) == 0 &&
        point.x >= (a.x < b.x ? a.x : b.x) && point.x <= (a.x > b.x ? a.x : b.x) &&
        point.y >= (a.y < b.y ? a.y : b.y) && point.y <= (a.y > b.y ? a.y : b.y);
}

static size_t mark_boundary(const point_t *points, size_t count, uint8_t *boundary) {
    for (size_t i = 0; i < count; ++i) boundary[i] = 0;
    if (count <= 2) {
        for (size_t i = 0; i < count; ++i) boundary[i] = 1;
        return count;
    }

    point_t hull[2 * MAX_POINTS];
    size_t hull_count = 0;
    for (size_t i = 0; i < count; ++i) {
        while (hull_count >= 2 && cross(hull[hull_count - 2], hull[hull_count - 1], points[i]) <= 0)
            --hull_count;
        hull[hull_count++] = points[i];
    }
    const size_t lower_count = hull_count;
    for (size_t i = count - 1; i > 0; --i) {
        const point_t point = points[i - 1];
        while (hull_count > lower_count &&
               cross(hull[hull_count - 2], hull[hull_count - 1], point) <= 0)
            --hull_count;
        hull[hull_count++] = point;
    }
    if (hull_count > 1) --hull_count;
    if (hull_count <= 2) {
        for (size_t i = 0; i < count; ++i) boundary[i] = 1;
        return count;
    }

    size_t marked = 0;
    for (size_t i = 0; i < count; ++i) {
        for (size_t edge = 0; edge < hull_count; ++edge) {
            if (on_segment(points[i], hull[edge], hull[(edge + 1) % hull_count])) {
                boundary[i] = 1;
                ++marked;
                break;
            }
        }
    }
    return marked;
}

int64_t convex_layers(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > 1 + 2 * MAX_POINTS) return -1;
    const int64_t count_value = input[0];
    if (count_value < 0 || count_value > MAX_POINTS || length != 1 + 2 * (size_t)count_value)
        return -1;

    point_t points[MAX_POINTS];
    size_t count = 0;
    for (size_t i = 0; i < (size_t)count_value; ++i) {
        const int64_t x = input[1 + 2 * i], y = input[2 + 2 * i];
        if (x < -COORD_LIMIT || x > COORD_LIMIT || y < -COORD_LIMIT || y > COORD_LIMIT) return -1;
        size_t duplicate = 0;
        while (duplicate < count && (points[duplicate].x != x || points[duplicate].y != y)) ++duplicate;
        if (duplicate == count) points[count++] = (point_t){x, y};
    }

    int64_t layers = 0;
    while (count > 0) {
        sort_points(points, count);
        uint8_t boundary[MAX_POINTS];
        const size_t removed = mark_boundary(points, count, boundary);
        if (removed == 0) return -1;
        size_t kept = 0;
        for (size_t i = 0; i < count; ++i)
            if (!boundary[i]) points[kept++] = points[i];
        count = kept;
        ++layers;
    }
    return layers;
}

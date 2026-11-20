#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 16
#define MAX_PARSEABLE_LENGTH 38

typedef struct { int64_t x, y; } Point;
typedef struct { int64_t x, y; } Vector;
typedef struct { int64_t edge, numerator, denominator; } Hit;

static int polar_half(Vector v) {
    return (v.y > 0 || (v.y == 0 && v.x >= 0)) ? 0 : 1;
}

static int angle_before(Vector a, Vector b) {
    int ah = polar_half(a), bh = polar_half(b);
    if (ah != bh) return ah < bh;
    return a.x * b.y - a.y * b.x > 0;
}

static size_t rotation_minimum(const Vector *edges, size_t count) {
    size_t low = 0, high = count - 1;
    while (low < high) {
        size_t middle = (low + high) / 2;
        if (angle_before(edges[middle], edges[high])) high = middle;
        else low = middle + 1;
    }
    return low;
}

static size_t support_edge(const Vector *edges, size_t count, Vector target) {
    size_t pivot = rotation_minimum(edges, count);
    size_t low = 0, high = count;
    while (low < high) {
        size_t middle = (low + high) / 2;
        if (angle_before(edges[(pivot + middle) % count], target)) low = middle + 1;
        else high = middle;
    }
    return (pivot + low) % count;
}

static int64_t line_value(Point p, Point origin, Vector direction) {
    return direction.x * (p.y - origin.y) - direction.y * (p.x - origin.x);
}

static int64_t line_parameter(Point p, Point origin, Vector direction) {
    return (p.x - origin.x) * direction.x + (p.y - origin.y) * direction.y;
}

static Hit crossing(const Point *points, size_t count, Point origin, Vector direction,
                    size_t start, size_t end, int increasing) {
    size_t span = (end + count - start) % count;
    size_t low = 0, high = span;
    while (high - low > 1) {
        size_t middle = (low + high) / 2;
        int64_t value = line_value(points[(start + middle) % count], origin, direction);
        if (increasing ? value < 0 : value > 0) low = middle;
        else high = middle;
    }
    size_t index = (start + low) % count;
    int64_t value = line_value(points[index], origin, direction);
    if (line_value(points[(start + high) % count], origin, direction) == 0)
        index = (start + high) % count;
    if (value == 0 || line_value(points[index], origin, direction) == 0) {
        return (Hit){(int64_t)index, line_parameter(points[index], origin, direction), 1};
    }

    size_t next = (index + 1) % count;
    int64_t next_value = line_value(points[next], origin, direction);
    int64_t denominator = value - next_value;
    int64_t edge_dot = (points[next].x - points[index].x) * direction.x +
                       (points[next].y - points[index].y) * direction.y;
    int64_t numerator = line_parameter(points[index], origin, direction) * denominator + value * edge_dot;
    if (denominator < 0) { numerator = -numerator; denominator = -denominator; }
    return (Hit){(int64_t)index, numerator, denominator};
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

int64_t line_hull_intersection(const int64_t *input, size_t length,
                               uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    int64_t n_value = input[0];
    if (n_value < 3 || n_value > MAX_VERTICES) return -1;
    size_t n = (size_t)n_value;
    if (length != 5 + 2 * n) return -1;
    Point origin = {input[1], input[2]};
    Point line_end = {input[3], input[4]};
    if (origin.x < -50 || origin.x > 50 || origin.y < -50 || origin.y > 50 ||
        line_end.x < -50 || line_end.x > 50 || line_end.y < -50 || line_end.y > 50)
        return -1;
    Vector direction = {line_end.x - origin.x, line_end.y - origin.y};
    if (direction.x == 0 && direction.y == 0) return -1;

    Point points[MAX_VERTICES];
    Vector edges[MAX_VERTICES];
    for (size_t i = 0; i < n; ++i) {
        points[i] = (Point){input[5 + 2 * i], input[6 + 2 * i]};
        if (points[i].x < -50 || points[i].x > 50 || points[i].y < -50 || points[i].y > 50)
            return -1;
        for (size_t j = 0; j < i; ++j)
            if (points[j].x == points[i].x && points[j].y == points[i].y) return -1;
    }
    int64_t area2 = 0;
    for (size_t i = 0; i < n; ++i) {
        size_t next = (i + 1) % n;
        edges[i] = (Vector){points[next].x - points[i].x, points[next].y - points[i].y};
        area2 += points[i].x * points[next].y - points[next].x * points[i].y;
    }
    if (area2 <= 0) return -1;
    for (size_t i = 0; i < n; ++i) {
        size_t next = (i + 1) % n;
        for (size_t j = 0; j < n; ++j) {
            if (j == i || j == next) continue;
            int64_t side = edges[i].x * (points[j].y - points[i].y) -
                           edges[i].y * (points[j].x - points[i].x);
            if (side <= 0) return -1;
        }
    }

    size_t maximum = support_edge(edges, n, (Vector){-direction.x, -direction.y});
    size_t minimum = support_edge(edges, n, direction);
    int64_t max_value = line_value(points[maximum], origin, direction);
    int64_t min_value = line_value(points[minimum], origin, direction);
    int64_t first = -1, second = -1;
    if (min_value > 0 || max_value < 0) {
        first = second = -1;
    } else if (min_value == 0 || max_value == 0) {
        size_t touch = min_value == 0 ? minimum : maximum;
        size_t next = (touch + 1) % n, previous = (touch + n - 1) % n;
        if (line_value(points[touch], origin, direction) == 0 &&
            line_value(points[next], origin, direction) == 0) first = second = (int64_t)touch;
        else if (line_value(points[previous], origin, direction) == 0 &&
                 line_value(points[touch], origin, direction) == 0) first = second = (int64_t)previous;
        else { first = (int64_t)touch; second = -1; }
    } else {
        Hit a = crossing(points, n, origin, direction, maximum, minimum, 0);
        Hit b = crossing(points, n, origin, direction, minimum, maximum, 1);
        if (a.numerator * b.denominator <= b.numerator * a.denominator) {
            first = a.edge; second = b.edge;
        } else { first = b.edge; second = a.edge; }
    }
    if (output == NULL || capacity < 16) return -2;
    store_i64_le(output, 0, first);
    store_i64_le(output, 8, second);
    return 16;
}

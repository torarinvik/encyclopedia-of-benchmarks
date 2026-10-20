#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 8
#define MAX_VERTICES (MAX_POINTS + 3)
#define MAX_WORK_TRIANGLES (2 * MAX_POINTS + 1)
#define MAX_WORK_EDGES (3 * MAX_WORK_TRIANGLES)
#define MAX_TRIANGLES (2 * MAX_POINTS - 5)
#define MAX_OUTPUT_BYTES (8 * (1 + 3 * MAX_TRIANGLES))
#define CIRCUMCIRCLE_EPSILON 1e-4

typedef struct { double x, y; } Point;
typedef struct { int a, b; } Edge;
typedef struct { int a, b, c; double cx, cy, radius_squared; } Triangle;

static int64_t orient_i64(int64_t ax, int64_t ay, int64_t bx, int64_t by,
                          int64_t cx, int64_t cy)
{
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

static int64_t incircle_i64(int64_t ax, int64_t ay, int64_t bx, int64_t by,
                            int64_t cx, int64_t cy, int64_t dx, int64_t dy)
{
    const int64_t a_x = ax - dx, a_y = ay - dy;
    const int64_t b_x = bx - dx, b_y = by - dy;
    const int64_t c_x = cx - dx, c_y = cy - dy;
    const int64_t a_sq = a_x * a_x + a_y * a_y;
    const int64_t b_sq = b_x * b_x + b_y * b_y;
    const int64_t c_sq = c_x * c_x + c_y * c_y;
    return a_sq * (b_x * c_y - b_y * c_x)
         - b_sq * (a_x * c_y - a_y * c_x)
         + c_sq * (a_x * b_y - a_y * b_x);
}

static int same_edge(Edge a, Edge b)
{
    return (a.a == b.a && a.b == b.b) || (a.a == b.b && a.b == b.a);
}

static Triangle make_triangle(const Point *points, int a, int b, int c)
{
    const Point p0 = points[a], p1 = points[b], p2 = points[c];
    const double ax = p1.x - p0.x, ay = p1.y - p0.y;
    const double bx = p2.x - p0.x, by = p2.y - p0.y;
    const double m = p1.x * p1.x - p0.x * p0.x + p1.y * p1.y - p0.y * p0.y;
    const double u = p2.x * p2.x - p0.x * p0.x + p2.y * p2.y - p0.y * p0.y;
    const double scale = 1.0 / (2.0 * (ax * by - ay * bx));
    const double center_x = ((p2.y - p0.y) * m + (p0.y - p1.y) * u) * scale;
    const double center_y = ((p0.x - p2.x) * m + (p1.x - p0.x) * u) * scale;
    const double dx = p0.x - center_x, dy = p0.y - center_y;
    Triangle result = {a, b, c, center_x, center_y, dx * dx + dy * dy};
    return result;
}

static void sort_triangle_indices(int *a, int *b, int *c)
{
    if (*a > *b) { const int temp = *a; *a = *b; *b = temp; }
    if (*b > *c) { const int temp = *b; *b = *c; *c = temp; }
    if (*a > *b) { const int temp = *a; *a = *b; *b = temp; }
}

static int triangle_less(Triangle a, Triangle b)
{
    if (a.a != b.a) return a.a < b.a;
    if (a.b != b.b) return a.b < b.b;
    return a.c < b.c;
}

static void put_i64(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)bits;
        bits >>= 8;
    }
}

int64_t delaunay_triangulation(const int64_t *values, size_t length,
                               uint8_t *output, size_t capacity)
{
    if (values == NULL || length < 7 || length > 17 || values[0] < 3 || values[0] > MAX_POINTS ||
        length != 1 + 2 * (size_t)values[0]) return -1;
    const int point_count = (int)values[0];
    int64_t input_x[MAX_POINTS], input_y[MAX_POINTS];
    Point points[MAX_VERTICES] = {{0.0, 0.0}};
    int64_t min_x = 0, max_x = 0, min_y = 0, max_y = 0;
    for (int i = 0; i < point_count; ++i) {
        const int64_t x = values[1 + 2 * i], y = values[2 + 2 * i];
        if (x < -10 || x > 10 || y < -10 || y > 10) return -1;
        for (int j = 0; j < i; ++j) if (input_x[j] == x && input_y[j] == y) return -1;
        input_x[i] = x; input_y[i] = y;
        points[i].x = (double)x; points[i].y = (double)y;
        if (i == 0) { min_x = max_x = x; min_y = max_y = y; }
        else {
            if (x < min_x) min_x = x; if (x > max_x) max_x = x;
            if (y < min_y) min_y = y; if (y > max_y) max_y = y;
        }
    }
    for (int a = 0; a < point_count; ++a)
        for (int b = a + 1; b < point_count; ++b)
            for (int c = b + 1; c < point_count; ++c)
                if (orient_i64(input_x[a], input_y[a], input_x[b], input_y[b], input_x[c], input_y[c]) == 0) return -1;
    for (int a = 0; a < point_count; ++a)
        for (int b = a + 1; b < point_count; ++b)
            for (int c = b + 1; c < point_count; ++c)
                for (int d = c + 1; d < point_count; ++d)
                    if (incircle_i64(input_x[a], input_y[a], input_x[b], input_y[b], input_x[c], input_y[c], input_x[d], input_y[d]) == 0) return -1;

    const int64_t dx = max_x - min_x, dy = max_y - min_y;
    const int64_t dmax = dx > dy ? dx : dy;
    const double midx = ((double)min_x + (double)max_x) / 2.0;
    const double midy = ((double)min_y + (double)max_y) / 2.0;
    const int super0 = point_count, super1 = point_count + 1, super2 = point_count + 2;
    points[super0] = (Point){midx - 20.0 * (double)dmax, midy - (double)dmax};
    points[super1] = (Point){midx, midy + 20.0 * (double)dmax};
    points[super2] = (Point){midx + 20.0 * (double)dmax, midy - (double)dmax};
    for (int a = 0; a < point_count + 3; ++a)
        for (int b = a + 1; b < point_count + 3; ++b)
            for (int c = b + 1; c < point_count + 3; ++c) {
                const double area2 = (points[b].x - points[a].x) * (points[c].y - points[a].y)
                                   - (points[b].y - points[a].y) * (points[c].x - points[a].x);
                if (area2 == 0.0) return -1;
            }

    Triangle current[MAX_WORK_TRIANGLES], next[MAX_WORK_TRIANGLES];
    Edge edges[MAX_WORK_EDGES];
    int current_count = 1;
    current[0] = make_triangle(points, super0, super1, super2);
    for (int point = 0; point < point_count; ++point) {
        int edge_count = 0, next_count = 0;
        for (int i = 0; i < current_count; ++i) {
            const Triangle t = current[i];
            const double xdiff = t.cx - points[point].x, ydiff = t.cy - points[point].y;
            const double distance = xdiff * xdiff + ydiff * ydiff;
            if (distance - t.radius_squared <= CIRCUMCIRCLE_EPSILON) {
                edges[edge_count++] = (Edge){t.a, t.b};
                edges[edge_count++] = (Edge){t.b, t.c};
                edges[edge_count++] = (Edge){t.a, t.c};
            } else {
                if (next_count >= MAX_WORK_TRIANGLES) return -1;
                next[next_count++] = t;
            }
        }
        uint8_t remove[MAX_WORK_EDGES] = {0};
        for (int i = 0; i < edge_count; ++i)
            for (int j = 0; j < edge_count; ++j)
                if (i != j && same_edge(edges[i], edges[j])) remove[i] = remove[j] = 1;
        for (int i = 0; i < edge_count; ++i) if (!remove[i]) {
            if (next_count >= MAX_WORK_TRIANGLES) return -1;
            next[next_count++] = make_triangle(points, edges[i].a, edges[i].b, point);
        }
        for (int i = 0; i < next_count; ++i) current[i] = next[i];
        current_count = next_count;
    }

    Triangle result[MAX_TRIANGLES];
    int result_count = 0;
    for (int i = 0; i < current_count; ++i) {
        Triangle t = current[i];
        if (t.a >= point_count || t.b >= point_count || t.c >= point_count) continue;
        if (result_count >= MAX_TRIANGLES) return -1;
        sort_triangle_indices(&t.a, &t.b, &t.c);
        int j = result_count++;
        while (j > 0 && triangle_less(t, result[j - 1])) { result[j] = result[j - 1]; --j; }
        result[j] = t;
    }
    if (result_count == 0) return -1;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    put_i64(staged, 0, result_count);
    for (int i = 0; i < result_count; ++i) {
        put_i64(staged, 8 + 24 * (size_t)i, result[i].a);
        put_i64(staged, 16 + 24 * (size_t)i, result[i].b);
        put_i64(staged, 24 + 24 * (size_t)i, result[i].c);
    }
    const size_t required = 8 + 24 * (size_t)result_count;
    if (output == NULL || capacity < required) return -2;
    for (size_t i = 0; i < required; ++i) output[i] = staged[i];
    return (int64_t)required;
}

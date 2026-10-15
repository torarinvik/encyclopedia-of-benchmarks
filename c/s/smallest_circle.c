/* Bounded deterministic minimum enclosing circle by support-set enumeration. */
#include <math.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_POINTS 12
typedef struct { int64_t x, y; } point_t;
typedef struct { double x, y, radius; } circle_t;

static double squared_distance(double x, double y, point_t p)
{
    const double dx = x - (double)p.x;
    const double dy = y - (double)p.y;
    return dx * dx + dy * dy;
}

static bool contains_all(const point_t *points, size_t count, circle_t circle)
{
    const double radius_squared = circle.radius * circle.radius;
    for (size_t index = 0; index < count; ++index)
        if (squared_distance(circle.x, circle.y, points[index]) > radius_squared + 1e-12) return false;
    return true;
}

static void consider(const point_t *points, size_t count, circle_t candidate,
                     circle_t *best, bool *has_best)
{
    if (!contains_all(points, count, candidate)) return;
    if (!*has_best || candidate.radius <= best->radius) {
        *best = candidate;
        *has_best = true;
    }
}

static void write_f64_le(uint8_t *output, size_t offset, double value)
{
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t smallest_circle(const int64_t *values, size_t length,
                        uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2 || length > 2 * MAX_POINTS || length % 2 != 0) return -1;
    const size_t count = length / 2;
    point_t points[MAX_POINTS];
    for (size_t i = 0; i < count; ++i) {
        const int64_t x = values[2 * i], y = values[2 * i + 1];
        if (x < -100 || x > 100 || y < -100 || y > 100) return -1;
        points[i] = (point_t){x, y};
    }
    if (output == NULL || output_capacity < 24) return -2;

    circle_t best = {0.0, 0.0, 0.0};
    bool has_best = false;
    if (count == 1) {
        best = (circle_t){(double)points[0].x, (double)points[0].y, 0.0};
        has_best = true;
    }
    for (size_t i = 0; i + 2 < count; ++i) {
        for (size_t j = i + 1; j + 1 < count; ++j) {
            for (size_t k = j + 1; k < count; ++k) {
                const int64_t denominator = 2 * (points[i].x * (points[j].y - points[k].y) +
                    points[j].x * (points[k].y - points[i].y) + points[k].x * (points[i].y - points[j].y));
                if (denominator == 0) continue;
                const int64_t norm_i = points[i].x * points[i].x + points[i].y * points[i].y;
                const int64_t norm_j = points[j].x * points[j].x + points[j].y * points[j].y;
                const int64_t norm_k = points[k].x * points[k].x + points[k].y * points[k].y;
                const int64_t numerator_x = norm_i * (points[j].y - points[k].y) +
                    norm_j * (points[k].y - points[i].y) + norm_k * (points[i].y - points[j].y);
                const int64_t numerator_y = norm_i * (points[k].x - points[j].x) +
                    norm_j * (points[i].x - points[k].x) + norm_k * (points[j].x - points[i].x);
                const double cx = (double)numerator_x / (double)denominator;
                const double cy = (double)numerator_y / (double)denominator;
                const double dx = cx - (double)points[i].x, dy = cy - (double)points[i].y;
                consider(points, count, (circle_t){cx, cy, sqrt(dx * dx + dy * dy)}, &best, &has_best);
            }
        }
    }
    for (size_t i = 0; i + 1 < count; ++i) {
        for (size_t j = i + 1; j < count; ++j) {
            const double cx = ((double)points[i].x + (double)points[j].x) / 2.0;
            const double cy = ((double)points[i].y + (double)points[j].y) / 2.0;
            const double dx = cx - (double)points[i].x, dy = cy - (double)points[i].y;
            consider(points, count, (circle_t){cx, cy, sqrt(dx * dx + dy * dy)}, &best, &has_best);
        }
    }
    if (!has_best) return -1;
    write_f64_le(output, 0, best.x);
    write_f64_le(output, 8, best.y);
    write_f64_le(output, 16, best.radius);
    return 1;
}

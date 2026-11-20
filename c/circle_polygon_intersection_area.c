#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_VERTICES = 16, MAX_INPUT = 37, MAX_COORDINATE = 32 };
#define INVALID_RESULT (-1.0e300)

double circle_polygon_intersection_area(const int64_t *values, size_t length) {
    if (values == NULL || length < 10 || length > MAX_INPUT) return INVALID_RESULT;
    const int64_t n_value = values[0], cx = values[1], cy = values[2], radius_value = values[3];
    if (n_value < 3 || n_value > MAX_VERTICES) return INVALID_RESULT;
    if (length != (size_t)(4 + 2 * n_value) ||
        cx < -MAX_COORDINATE || cx > MAX_COORDINATE ||
        cy < -MAX_COORDINATE || cy > MAX_COORDINATE ||
        radius_value < 1 || radius_value > MAX_COORDINATE) return INVALID_RESULT;

    const int n = (int)n_value;
    int64_t x[MAX_VERTICES], y[MAX_VERTICES];
    for (int i = 0; i < n; ++i) {
        x[i] = values[4 + 2 * i];
        y[i] = values[5 + 2 * i];
        if (x[i] < -MAX_COORDINATE || x[i] > MAX_COORDINATE ||
            y[i] < -MAX_COORDINATE || y[i] > MAX_COORDINATE) return INVALID_RESULT;
    }

    for (int i = 0; i < n; ++i) {
        const int next = (i + 1) % n;
        const int64_t dx = x[next] - x[i], dy = y[next] - y[i];
        for (int j = 0; j < n; ++j) {
            if (j == i || j == next) continue;
            const int64_t side = dx * (y[j] - y[i]) - dy * (x[j] - x[i]);
            if (side <= 0) return INVALID_RESULT;
        }
        const int64_t center_side = dx * (cy - y[i]) - dy * (cx - x[i]);
        if (center_side <= 0) return INVALID_RESULT;
    }

    const double radius = (double)radius_value;
    const double radius_squared = radius * radius;
    double doubled_area = 0.0;
    for (int i = 0; i < n; ++i) {
        const int next = (i + 1) % n;
        const double px = (double)(x[i] - cx), py = (double)(y[i] - cy);
        const double qx = (double)(x[next] - cx), qy = (double)(y[next] - cy);
        const double dx = qx - px, dy = qy - py;
        const double edge_squared = dx * dx + dy * dy;
        const double projection = px * dx + py * dy;
        const double constant = px * px + py * py - radius_squared;
        const double discriminant = projection * projection - edge_squared * constant;
        const double full_angle = atan2(px * qy - py * qx, px * qx + py * qy);
        if (discriminant <= 0.0) {
            doubled_area += radius_squared * full_angle;
            continue;
        }

        const double root = sqrt(discriminant);
        const double first = (-projection - root) / edge_squared;
        const double second = (-projection + root) / edge_squared;
        if (second < 0.0 || first > 1.0) {
            doubled_area += radius_squared * full_angle;
            continue;
        }
        const double start = first > 0.0 ? first : 0.0;
        const double stop = second < 1.0 ? second : 1.0;
        const double ux = px + start * dx, uy = py + start * dy;
        const double vx = px + stop * dx, vy = py + stop * dy;
        const double first_angle = atan2(px * uy - py * ux, px * ux + py * uy);
        const double last_angle = atan2(vx * qy - vy * qx, vx * qx + vy * qy);
        doubled_area += radius_squared * (first_angle + last_angle) + ux * vy - uy * vx;
    }
    return 0.5 * doubled_area;
}

module circle_polygon_intersection_area;

extern fn double atan2(double y, double x);
extern fn double sqrt(double value);

const long MAX_VERTICES = 16;
const usz MAX_INPUT = 37;
const long MAX_COORDINATE = 32;
const double INVALID_RESULT = -1.0e300;

fn double circle_polygon_intersection_area(long* values, usz length)
        @export("circle_polygon_intersection_area") {
    if (values == null || length < 10 || length > MAX_INPUT) return INVALID_RESULT;
    long n = values[0], cx = values[1], cy = values[2], radius_value = values[3];
    if (n < 3 || n > MAX_VERTICES) return INVALID_RESULT;
    if (length != (usz)(4 + 2 * n) || cx < -MAX_COORDINATE || cx > MAX_COORDINATE ||
        cy < -MAX_COORDINATE || cy > MAX_COORDINATE ||
        radius_value < 1 || radius_value > MAX_COORDINATE) return INVALID_RESULT;

    long[MAX_VERTICES] x = {}, y = {};
    for (long i = 0; i < n; i++) {
        x[i] = values[4 + 2 * (usz)i];
        y[i] = values[5 + 2 * (usz)i];
        if (x[i] < -MAX_COORDINATE || x[i] > MAX_COORDINATE ||
            y[i] < -MAX_COORDINATE || y[i] > MAX_COORDINATE) return INVALID_RESULT;
    }
    for (long i = 0; i < n; i++) {
        long next = (i + 1) % n;
        long dx = x[next] - x[i], dy = y[next] - y[i];
        for (long j = 0; j < n; j++) {
            if (j == i || j == next) continue;
            if (dx * (y[j] - y[i]) - dy * (x[j] - x[i]) <= 0) return INVALID_RESULT;
        }
        if (dx * (cy - y[i]) - dy * (cx - x[i]) <= 0) return INVALID_RESULT;
    }

    double radius = (double)radius_value, radius_squared = radius * radius;
    double doubled_area = 0.0;
    for (long i = 0; i < n; i++) {
        long next = (i + 1) % n;
        double px = (double)(x[i] - cx), py = (double)(y[i] - cy);
        double qx = (double)(x[next] - cx), qy = (double)(y[next] - cy);
        double dx = qx - px, dy = qy - py;
        double edge_squared = dx * dx + dy * dy;
        double projection = px * dx + py * dy;
        double constant = px * px + py * py - radius_squared;
        double discriminant = projection * projection - edge_squared * constant;
        double full_angle = atan2(px * qy - py * qx, px * qx + py * qy);
        if (discriminant <= 0.0) {
            doubled_area += radius_squared * full_angle;
            continue;
        }
        double root = sqrt(discriminant);
        double first = (-projection - root) / edge_squared;
        double second = (-projection + root) / edge_squared;
        if (second < 0.0 || first > 1.0) {
            doubled_area += radius_squared * full_angle;
            continue;
        }
        double start = first > 0.0 ? first : 0.0;
        double stop = second < 1.0 ? second : 1.0;
        double ux = px + start * dx, uy = py + start * dy;
        double vx = px + stop * dx, vy = py + stop * dy;
        double first_angle = atan2(px * uy - py * ux, px * ux + py * uy);
        double last_angle = atan2(vx * qy - vy * qx, vx * qx + vy * qy);
        doubled_area += radius_squared * (first_angle + last_angle) + ux * vy - uy * vx;
    }
    return 0.5 * doubled_area;
}

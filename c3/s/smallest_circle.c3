module smallest_circle;

extern fn double sqrt(double value);

const usz MAX_POINTS = 12;

struct Circle { double x; double y; double radius; bool valid; }

fn bool contains_all(Circle circle, long* values, usz count) {
    double radius_squared = circle.radius * circle.radius;
    for (usz index = 0; index < count; index++) {
        double dx = (double)values[2 * index] - circle.x;
        double dy = (double)values[2 * index + 1] - circle.y;
        if (dx * dx + dy * dy > radius_squared + 1e-12) return false;
    }
    return true;
}

fn void consider(Circle candidate, long* values, usz count, Circle* best) {
    if (contains_all(candidate, values, count) && (!best.valid || candidate.radius <= best.radius)) {
        candidate.valid = true;
        best.x = candidate.x;
        best.y = candidate.y;
        best.radius = candidate.radius;
        best.valid = true;
    }
}

fn void write_f64_le(double value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long smallest_circle(long* values, usz length, char* output, usz output_capacity)
        @export("smallest_circle") {
    if (values == null || length < 2 || length > 2 * MAX_POINTS || length % 2 != 0) return -1;
    usz count = length / 2;
    for (usz index = 0; index < length; index++)
        if (values[index] < -100 || values[index] > 100) return -1;

    Circle best = {0.0, 0.0, 0.0, false};
    if (count == 1) {
        best = {(double)values[0], (double)values[1], 0.0, true};
    } else {
        for (usz i = 0; i < count; i++) {
            double ax = (double)values[2 * i], ay = (double)values[2 * i + 1];
            for (usz j = i + 1; j < count; j++) {
                double bx = (double)values[2 * j], by = (double)values[2 * j + 1];
                for (usz k = j + 1; k < count; k++) {
                    double cx = (double)values[2 * k], cy = (double)values[2 * k + 1];
                    double denominator = 2.0 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by));
                    if (denominator == 0.0) continue;
                    double a_squared = ax * ax + ay * ay;
                    double b_squared = bx * bx + by * by;
                    double c_squared = cx * cx + cy * cy;
                    double center_x = (a_squared * (by - cy) + b_squared * (cy - ay) +
                            c_squared * (ay - by)) / denominator;
                    double center_y = (a_squared * (cx - bx) + b_squared * (ax - cx) +
                            c_squared * (bx - ax)) / denominator;
                    double dx = center_x - ax, dy = center_y - ay;
                    Circle candidate = {center_x, center_y, sqrt(dx * dx + dy * dy), false};
                    consider(candidate, values, count, &best);
                }
            }
        }
        for (usz i = 0; i < count; i++) {
            double ax = (double)values[2 * i], ay = (double)values[2 * i + 1];
            for (usz j = i + 1; j < count; j++) {
                double bx = (double)values[2 * j], by = (double)values[2 * j + 1];
                double center_x = (ax + bx) / 2.0, center_y = (ay + by) / 2.0;
                double dx = bx - ax, dy = by - ay;
                Circle candidate = {center_x, center_y, sqrt(dx * dx + dy * dy) / 2.0, false};
                consider(candidate, values, count, &best);
            }
        }
    }
    if (!best.valid) return -1;
    if (output == null || output_capacity < 24) return -2;
    write_f64_le(best.x, output, 0);
    write_f64_le(best.y, output, 8);
    write_f64_le(best.radius, output, 16);
    return 1;
}

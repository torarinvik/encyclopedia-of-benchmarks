module line_intersection;

const long COORDINATE_LIMIT = 10000;
struct Point { long x; long y; }

bool same(Point a, Point b) { return a.x == b.x && a.y == b.y; }
long cross(Point a, Point b, Point c) {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}
bool on_segment(Point a, Point b, Point p) {
    return cross(a, b, p) == 0 && p.x >= (a.x < b.x ? a.x : b.x) &&
        p.x <= (a.x > b.x ? a.x : b.x) && p.y >= (a.y < b.y ? a.y : b.y) &&
        p.y <= (a.y > b.y ? a.y : b.y);
}
long write_point(char* output, usz capacity, double x, double y) {
    if (output == null || capacity < 16) return -2;
    ulong x_bits = @bitcast(ulong, x);
    ulong y_bits = @bitcast(ulong, y);
    for (usz byte = 0; byte < 8; byte++) {
        output[byte] = (char)(x_bits >> (8 * byte));
        output[8 + byte] = (char)(y_bits >> (8 * byte));
    }
    return 1;
}

fn long line_intersection(long* values, usz length, char* output, usz output_capacity)
    @export("line_intersection") {
    if (length != 9 || values == null) return -1;
    for (usz index = 0; index < 8; index++)
        if (values[index] < -COORDINATE_LIMIT || values[index] > COORDINATE_LIMIT) return -1;
    if (values[8] != 0 && values[8] != 1) return -1;
    Point p1 = {values[0], values[1]}, p2 = {values[2], values[3]};
    Point q1 = {values[4], values[5]}, q2 = {values[6], values[7]};
    bool segments = values[8] == 1;
    bool p_point = same(p1, p2), q_point = same(q1, q2);
    if (!segments && (p_point || q_point)) return -1;
    if (segments && p_point && q_point)
        return same(p1, q1) ? write_point(output, output_capacity, (double)p1.x, (double)p1.y) : 0;
    if (segments && p_point)
        return on_segment(q1, q2, p1) ? write_point(output, output_capacity, (double)p1.x, (double)p1.y) : 0;
    if (segments && q_point)
        return on_segment(p1, p2, q1) ? write_point(output, output_capacity, (double)q1.x, (double)q1.y) : 0;
    long denominator = (p1.x - p2.x) * (q1.y - q2.y) - (p1.y - p2.y) * (q1.x - q2.x);
    if (denominator == 0) return 0;
    long determinant_p = p1.x * p2.y - p1.y * p2.x;
    long determinant_q = q1.x * q2.y - q1.y * q2.x;
    long numerator_x = determinant_p * (q1.x - q2.x) - (p1.x - p2.x) * determinant_q;
    long numerator_y = determinant_p * (q1.y - q2.y) - (p1.y - p2.y) * determinant_q;
    if (segments) {
        long den = denominator < 0 ? -denominator : denominator;
        long x = denominator < 0 ? -numerator_x : numerator_x;
        long y = denominator < 0 ? -numerator_y : numerator_y;
        long min_x = (p1.x < p2.x ? p1.x : p2.x) > (q1.x < q2.x ? q1.x : q2.x)
            ? (p1.x < p2.x ? p1.x : p2.x) : (q1.x < q2.x ? q1.x : q2.x);
        long max_x = (p1.x > p2.x ? p1.x : p2.x) < (q1.x > q2.x ? q1.x : q2.x)
            ? (p1.x > p2.x ? p1.x : p2.x) : (q1.x > q2.x ? q1.x : q2.x);
        long min_y = (p1.y < p2.y ? p1.y : p2.y) > (q1.y < q2.y ? q1.y : q2.y)
            ? (p1.y < p2.y ? p1.y : p2.y) : (q1.y < q2.y ? q1.y : q2.y);
        long max_y = (p1.y > p2.y ? p1.y : p2.y) < (q1.y > q2.y ? q1.y : q2.y)
            ? (p1.y > p2.y ? p1.y : p2.y) : (q1.y > q2.y ? q1.y : q2.y);
        if (x < min_x * den || x > max_x * den || y < min_y * den || y > max_y * den) return 0;
        return write_point(output, output_capacity, (double)x / (double)den, (double)y / (double)den);
    }
    return write_point(output, output_capacity, (double)numerator_x / (double)denominator,
                       (double)numerator_y / (double)denominator);
}

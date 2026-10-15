module line_segment_intersection;

const long COORDINATE_LIMIT = 10000;

struct Point { long x; long y; }

long orientation(Point a, Point b, Point c) {
    (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

bool on_segment(Point a, Point b, Point p) {
    orientation(a, b, p) == 0 && p.x >= (a.x < b.x ? a.x : b.x) &&
        p.x <= (a.x > b.x ? a.x : b.x) && p.y >= (a.y < b.y ? a.y : b.y) &&
        p.y <= (a.y > b.y ? a.y : b.y)
}

bool segments_intersect(Point a, Point b, Point c, Point d) {
    long ab_c = orientation(a, b, c);
    long ab_d = orientation(a, b, d);
    long cd_a = orientation(c, d, a);
    long cd_b = orientation(c, d, b);
    if (ab_c == 0 && on_segment(a, b, c)) return true;
    if (ab_d == 0 && on_segment(a, b, d)) return true;
    if (cd_a == 0 && on_segment(c, d, a)) return true;
    if (cd_b == 0 && on_segment(c, d, b)) return true;
    (ab_c < 0 && ab_d > 0 || ab_c > 0 && ab_d < 0) &&
        (cd_a < 0 && cd_b > 0 || cd_a > 0 && cd_b < 0)
}

fn long line_segment_intersection(long* values, usz length, char* output,
        usz output_capacity) @export("line_segment_intersection") {
    if (values == null || length != 8) return -1;
    for (usz index = 0; index < length; index++)
        if (values[index] < -COORDINATE_LIMIT || values[index] > COORDINATE_LIMIT) return -1;

    Point a = {values[0], values[1]};
    Point b = {values[2], values[3]};
    Point c = {values[4], values[5]};
    Point d = {values[6], values[7]};
    return segments_intersect(a, b, c, d) ? 1 : 0;
}

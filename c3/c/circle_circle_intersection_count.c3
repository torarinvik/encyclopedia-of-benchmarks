module circle_circle_intersection_count;

const long MAX_COORDINATE = 1000;
const long MAX_RADIUS = 1000;
const usz INPUT_LENGTH = 6;

fn long classify(long x1, long y1, long r1, long x2, long y2, long r2) {
    long dx = x2 - x1;
    long dy = y2 - y1;
    if (dx == 0 && dy == 0) return r1 == r2 ? 3 : 0;
    long a = -2 * dx;
    long b = -2 * dy;
    long c = dx * dx + dy * dy + r1 * r1 - r2 * r2;
    long discriminant = r1 * r1 * (a * a + b * b) - c * c;
    if (discriminant < 0) return 0;
    return discriminant == 0 ? 1 : 2;
}

fn long circle_circle_intersection_count(long* input, usz length)
        @export("circle_circle_intersection_count") {
    if (input == null || length != INPUT_LENGTH) return -1;
    long x1 = input[0], y1 = input[1], r1 = input[2];
    long x2 = input[3], y2 = input[4], r2 = input[5];
    if (x1 < -MAX_COORDINATE || x1 > MAX_COORDINATE ||
        y1 < -MAX_COORDINATE || y1 > MAX_COORDINATE ||
        x2 < -MAX_COORDINATE || x2 > MAX_COORDINATE ||
        y2 < -MAX_COORDINATE || y2 > MAX_COORDINATE ||
        r1 < 1 || r1 > MAX_RADIUS || r2 < 1 || r2 > MAX_RADIUS) return -1;
    return classify(x1, y1, r1, x2, y2, r2);
}

module sort_points_by_argument;

const usz MAX_N = 64;
const usz INPUT_MAX = 1 + 2 * MAX_N;
struct Point { long x; long y; }

fn int point_half(Point p) {
    if (p.y < 0) return 0;
    if (p.y == 0 && p.x >= 0) return 1;
    return 2;
}
fn bool point_less(Point a, Point b) {
    int ha = point_half(a), hb = point_half(b);
    if (ha != hb) return ha < hb;
    long cross = a.x * b.y - a.y * b.x;
    if (cross != 0) return cross > 0;
    long ra = a.x * a.x + a.y * a.y, rb = b.x * b.x + b.y * b.y;
    if (ra != rb) return ra < rb;
    if (a.x != b.x) return a.x < b.x;
    return a.y < b.y;
}
fn void store_le(uint8* output, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[at + byte] = (uint8)((bits >> (8 * byte)) & 255);
}

fn long sort_points_by_argument(long* input, usz length, uint8* output, usz capacity) @export("sort_points_by_argument") {
    if (input == null || length < 1 || length > INPUT_MAX) return -1;
    long nr = input[0];
    if (nr < 1 || nr > (long)MAX_N || length != 1 + 2 * (usz)nr) return -1;
    usz n = (usz)nr;
    Point[MAX_N] points;
    for (usz i = 0; i < n; i++) {
        points[i] = { input[1 + 2 * i], input[2 + 2 * i] };
        if (points[i].x < -1000000000 || points[i].x > 1000000000 || points[i].y < -1000000000 || points[i].y > 1000000000) return -1;
    }
    usz required = 16 * n;
    if (output == null || capacity < required) return -2;
    for (usz i = 1; i < n; i++) {
        Point item = points[i]; usz j = i;
        while (j > 0 && point_less(item, points[j - 1])) { points[j] = points[j - 1]; j--; }
        points[j] = item;
    }
    long[2 * MAX_N] staged;
    for (usz i = 0; i < n; i++) { staged[2 * i] = points[i].x; staged[2 * i + 1] = points[i].y; }
    for (usz i = 0; i < 2 * n; i++) store_le(output, 8 * i, staged[i]);
    return (long)required;
}

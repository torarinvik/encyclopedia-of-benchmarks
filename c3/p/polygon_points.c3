module polygon_points;

const usz MAX_INPUT_LENGTH = 66;
const long INVALID_RESULT = -1;

fn long abs_i64(long value) {
    return value < 0 ? -value : value;
}

fn long gcd_i64(long a, long b) {
    while (b != 0) {
        long temp = b;
        b = a % b;
        a = temp;
    }
    return a;
}

fn long cross(long x1, long y1, long x2, long y2) {
    return x1 * y2 - x2 * y1;
}

fn long polygon_points(long* values, usz length) @export("polygon_points") {
    if (values == null || length < 1 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long raw_n = values[0];
    if (raw_n < 3 || raw_n > 32 || length != 1 + 2 * (usz)raw_n) return INVALID_RESULT;
    usz n = (usz)raw_n;
    for (usz i = 0; i < 2 * n; i += 1) {
        if (values[1 + i] < -1000 || values[1 + i] > 1000) return INVALID_RESULT;
    }

    long origin_x = values[1], origin_y = values[2];
    long doubled_area = 0;
    for (usz i = 2; i < n; i += 1) {
        long x1 = values[1 + 2 * i] - origin_x;
        long y1 = values[2 + 2 * i] - origin_y;
        long x2 = values[1 + 2 * (i - 1)] - origin_x;
        long y2 = values[2 + 2 * (i - 1)] - origin_y;
        doubled_area += cross(x1, y1, x2, y2);
    }
    long area = abs_i64(doubled_area / 2);

    long boundary = raw_n;
    for (usz i = 0; i < n; i += 1) {
        usz next = (i + 1) % n;
        long dx = values[1 + 2 * i] - values[1 + 2 * next];
        long dy = values[2 + 2 * i] - values[2 + 2 * next];
        boundary += abs_i64(gcd_i64(dx, dy)) - 1;
    }
    return area + 1 - boundary / 2;
}

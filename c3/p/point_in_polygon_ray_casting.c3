module point_in_polygon_ray_casting;

const long MIN_VERTICES = 3;
const long MAX_VERTICES = 64;
const long MAX_COORDINATE = 1000000;

fn long point_in_polygon_ray_casting(long* values, usz length) @export("point_in_polygon_ray_casting") {
    if (values == null || length < 9 || length > 131) return -1;
    long n = values[0];
    if (n < MIN_VERTICES || n > MAX_VERTICES || length != (usz)(3 + 2 * n)) return -1;
    long qx = values[1];
    long qy = values[2];
    if (qx < -MAX_COORDINATE || qx > MAX_COORDINATE || qy < -MAX_COORDINATE || qy > MAX_COORDINATE) return -1;
    for (long i = 0; i < n; i++) {
        long x = values[3 + 2 * i];
        long y = values[4 + 2 * i];
        if (x < -MAX_COORDINATE || x > MAX_COORDINATE || y < -MAX_COORDINATE || y > MAX_COORDINATE) return -1;
    }

    bool inside = false;
    for (long i = 0; i < n; i++) {
        long j = (i + 1) % n;
        long ax = values[3 + 2 * i];
        long ay = values[4 + 2 * i];
        long bx = values[3 + 2 * j];
        long by = values[4 + 2 * j];
        long turn = (bx - ax) * (qy - ay) - (by - ay) * (qx - ax);
        if (turn == 0 && qx >= (if ax < bx: ax else: bx) && qx <= (if ax > bx: ax else: bx) &&
            qy >= (if ay < by: ay else: by) && qy <= (if ay > by: ay else: by)) return 1;
        if ((ay > qy) != (by > qy) && ((by > ay && turn > 0) || (by < ay && turn < 0))) inside = !inside;
    }
    return if inside: 1 else: 0;
}

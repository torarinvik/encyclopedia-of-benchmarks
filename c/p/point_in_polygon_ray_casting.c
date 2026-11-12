#include <stddef.h>
#include <stdint.h>

#define MIN_VERTICES 3
#define MAX_VERTICES 64
#define MAX_COORDINATE INT64_C(1000000)

static int64_t cross(int64_t ax, int64_t ay, int64_t bx, int64_t by,
                     int64_t px, int64_t py) {
    return (bx - ax) * (py - ay) - (by - ay) * (px - ax);
}

int64_t point_in_polygon_ray_casting(const int64_t *values, size_t length) {
    if (values == NULL || length < 9 || length > 3 + 2 * MAX_VERTICES) return -1;
    const int64_t n = values[0];
    if (n < MIN_VERTICES || n > MAX_VERTICES || length != (size_t)(3 + 2 * n)) return -1;
    const int64_t qx = values[1];
    const int64_t qy = values[2];
    if (qx < -MAX_COORDINATE || qx > MAX_COORDINATE ||
        qy < -MAX_COORDINATE || qy > MAX_COORDINATE) return -1;
    for (int64_t i = 0; i < n; ++i) {
        const int64_t x = values[3 + 2 * i];
        const int64_t y = values[4 + 2 * i];
        if (x < -MAX_COORDINATE || x > MAX_COORDINATE ||
            y < -MAX_COORDINATE || y > MAX_COORDINATE) return -1;
    }

    int inside = 0;
    for (int64_t i = 0; i < n; ++i) {
        const int64_t j = (i + 1) % n;
        const int64_t ax = values[3 + 2 * i];
        const int64_t ay = values[4 + 2 * i];
        const int64_t bx = values[3 + 2 * j];
        const int64_t by = values[4 + 2 * j];
        const int64_t turn = cross(ax, ay, bx, by, qx, qy);
        if (turn == 0 && qx >= (ax < bx ? ax : bx) && qx <= (ax > bx ? ax : bx) &&
            qy >= (ay < by ? ay : by) && qy <= (ay > by ? ay : by)) return 1;
        if ((ay > qy) != (by > qy) &&
            ((by > ay && turn > 0) || (by < ay && turn < 0))) inside = !inside;
    }
    return inside;
}

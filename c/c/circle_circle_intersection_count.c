#include <stddef.h>
#include <stdint.h>

enum { MAX_COORDINATE = 1000, MAX_RADIUS = 1000, INPUT_LENGTH = 6 };

static int64_t classify(int64_t x1, int64_t y1, int64_t r1,
                        int64_t x2, int64_t y2, int64_t r2) {
    const int64_t dx = x2 - x1;
    const int64_t dy = y2 - y1;
    if (dx == 0 && dy == 0) return r1 == r2 ? 3 : 0;

    const int64_t a = -2 * dx;
    const int64_t b = -2 * dy;
    const int64_t c = dx * dx + dy * dy + r1 * r1 - r2 * r2;
    const int64_t discriminant = r1 * r1 * (a * a + b * b) - c * c;
    if (discriminant < 0) return 0;
    return discriminant == 0 ? 1 : 2;
}

int64_t circle_circle_intersection_count(const int64_t *input, size_t length) {
    if (input == NULL || length != INPUT_LENGTH) return -1;
    const int64_t x1 = input[0], y1 = input[1], r1 = input[2];
    const int64_t x2 = input[3], y2 = input[4], r2 = input[5];
    if (x1 < -MAX_COORDINATE || x1 > MAX_COORDINATE ||
        y1 < -MAX_COORDINATE || y1 > MAX_COORDINATE ||
        x2 < -MAX_COORDINATE || x2 > MAX_COORDINATE ||
        y2 < -MAX_COORDINATE || y2 > MAX_COORDINATE ||
        r1 < 1 || r1 > MAX_RADIUS || r2 < 1 || r2 > MAX_RADIUS) return -1;
    return classify(x1, y1, r1, x2, y2, r2);
}

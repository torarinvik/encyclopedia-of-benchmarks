#include <stddef.h>
#include <stdint.h>

enum { MAX_COORDINATE = 100000, MAX_RADIUS = 100000, INPUT_LENGTH = 6 };

static int64_t count_tangents(int64_t x1, int64_t y1, int64_t r1,
                              int64_t x2, int64_t y2, int64_t r2) {
    const int64_t dx = x2 - x1;
    const int64_t dy = y2 - y1;
    const int64_t distance_squared = dx * dx + dy * dy;
    const int signs[2] = {-1, 1};
    int64_t candidates = 0;
    for (int i = 0; i < 2; ++i) {
        for (int j = 0; j < 2; ++j) {
            const int64_t difference = signs[j] * r2 - signs[i] * r1;
            if (distance_squared >= difference * difference) ++candidates;
        }
    }
    if (r1 == 0 && r2 == 0) return 1;
    if (r1 == 0 || r2 == 0) {
        const int64_t radius = r1 + r2;
        return distance_squared == radius * radius ? 1 : candidates / 2;
    }
    const int64_t radius_sum = r1 + r2;
    const int64_t radius_difference = r1 - r2;
    if (distance_squared == radius_sum * radius_sum ||
        distance_squared == radius_difference * radius_difference) {
        --candidates;
    }
    return candidates;
}

int64_t common_tangents_two_circles(const int64_t *input, size_t length) {
    if (!input || length != INPUT_LENGTH) return -1;
    const int64_t x1 = input[0], y1 = input[1], r1 = input[2];
    const int64_t x2 = input[3], y2 = input[4], r2 = input[5];
    if (x1 < -MAX_COORDINATE || x1 > MAX_COORDINATE ||
        y1 < -MAX_COORDINATE || y1 > MAX_COORDINATE ||
        x2 < -MAX_COORDINATE || x2 > MAX_COORDINATE ||
        y2 < -MAX_COORDINATE || y2 > MAX_COORDINATE ||
        r1 < 0 || r1 > MAX_RADIUS || r2 < 0 || r2 > MAX_RADIUS ||
        (x1 == x2 && y1 == y2)) return -1;
    return count_tangents(x1, y1, r1, x2, y2, r2);
}

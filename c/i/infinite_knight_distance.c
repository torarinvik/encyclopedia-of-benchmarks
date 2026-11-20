#include <stddef.h>
#include <stdint.h>

#define MAX_COORDINATE INT64_C(1000000000)

int64_t infinite_knight_distance(const int64_t *input, size_t length) {
    if (input == NULL || length != 2) return -1;
    const int64_t dx = input[0], dy = input[1];
    if (dx < -MAX_COORDINATE || dx > MAX_COORDINATE ||
        dy < -MAX_COORDINATE || dy > MAX_COORDINATE) return -1;
    const int64_t abs_x = dx < 0 ? -dx : dx;
    const int64_t abs_y = dy < 0 ? -dy : dy;
    const int64_t large = abs_x > abs_y ? abs_x : abs_y;
    const int64_t small = abs_x < abs_y ? abs_x : abs_y;
    if (large == 1 && small == 0) return 3;
    if (large == 2 && small == 2) return 4;
    int64_t distance = (large + 1) / 2;
    const int64_t diagonal_bound = (large + small + 2) / 3;
    if (diagonal_bound > distance) distance = diagonal_bound;
    if ((large + small - distance) % 2 != 0) ++distance;
    return distance;
}

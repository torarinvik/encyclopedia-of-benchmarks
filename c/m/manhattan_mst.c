#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MANHATTAN_MST_MAX_POINTS 32
#define MANHATTAN_MST_MAX_INPUT_LENGTH (1 + 2 * MANHATTAN_MST_MAX_POINTS)
#define MANHATTAN_MST_COORDINATE_LIMIT INT64_C(1000000)

int64_t manhattan_mst(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || length > MANHATTAN_MST_MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = values[0];
    if (count_value < 1 || count_value > MANHATTAN_MST_MAX_POINTS) return -1;
    const size_t count = (size_t)count_value;
    if (length != 1 + 2 * count) return -1;

    int64_t x[MANHATTAN_MST_MAX_POINTS];
    int64_t y[MANHATTAN_MST_MAX_POINTS];
    for (size_t point = 0; point < count; ++point) {
        x[point] = values[1 + 2 * point];
        y[point] = values[2 + 2 * point];
        if (x[point] < -MANHATTAN_MST_COORDINATE_LIMIT ||
            x[point] > MANHATTAN_MST_COORDINATE_LIMIT ||
            y[point] < -MANHATTAN_MST_COORDINATE_LIMIT ||
            y[point] > MANHATTAN_MST_COORDINATE_LIMIT) return -1;
    }

    bool in_tree[MANHATTAN_MST_MAX_POINTS] = {false};
    bool has_best[MANHATTAN_MST_MAX_POINTS] = {false};
    int64_t best[MANHATTAN_MST_MAX_POINTS] = {0};
    has_best[0] = true;
    int64_t total = 0;

    for (size_t step = 0; step < count; ++step) {
        size_t selected = count;
        for (size_t point = 0; point < count; ++point) {
            if (!in_tree[point] && has_best[point] &&
                (selected == count || best[point] < best[selected])) selected = point;
        }
        if (selected == count) return -1;
        in_tree[selected] = true;
        total += best[selected];

        for (size_t point = 0; point < count; ++point) {
            if (in_tree[point]) continue;
            const int64_t dx = x[selected] - x[point];
            const int64_t dy = y[selected] - y[point];
            const int64_t distance = (dx < 0 ? -dx : dx) + (dy < 0 ? -dy : dy);
            if (!has_best[point] || distance < best[point]) {
                has_best[point] = true;
                best[point] = distance;
            }
        }
    }
    return total;
}

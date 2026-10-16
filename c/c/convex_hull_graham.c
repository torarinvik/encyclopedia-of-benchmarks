#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 64

static int before_x(size_t left, size_t right, const int64_t *values) {
    return values[2 * left] < values[2 * right];
}

static void sort_indices(size_t *items, size_t *scratch, size_t begin, size_t end,
                         const int64_t *values) {
    if (end - begin < 2) return;
    const size_t middle = begin + (end - begin) / 2;
    sort_indices(items, scratch, begin, middle, values);
    sort_indices(items, scratch, middle, end, values);
    size_t left = begin, right = middle, out = begin;
    while (left < middle && right < end)
        scratch[out++] = before_x(items[right], items[left], values) ? items[right++] : items[left++];
    while (left < middle) scratch[out++] = items[left++];
    while (right < end) scratch[out++] = items[right++];
    for (size_t index = begin; index < end; ++index) items[index] = scratch[index];
}

static int64_t cross(size_t a, size_t b, size_t c, const int64_t *values) {
    const int64_t ax = values[2 * a], ay = values[2 * a + 1];
    const int64_t bx = values[2 * b], by = values[2 * b + 1];
    const int64_t cx = values[2 * c], cy = values[2 * c + 1];
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

/* Source orientation: 1 for clockwise, -1 for anticlockwise, 0 for collinear. */
static int orientation(size_t a, size_t b, size_t c, const int64_t *values) {
    const int64_t turn = cross(a, b, c, values);
    return turn < 0 ? 1 : turn > 0 ? -1 : 0;
}

static void put_index(uint8_t *output, size_t position, size_t id) {
    const uint32_t value = (uint32_t)id;
    for (size_t byte = 0; byte < 4; ++byte)
        output[4 * position + byte] = (uint8_t)(value >> (8 * byte));
}

int64_t convex_hull_graham(const int64_t *values, size_t length,
                           uint8_t *output, size_t output_capacity) {
    if (length % 2 != 0 || length > 2 * MAX_POINTS || values == NULL) return -1;
    const size_t count = length / 2;
    if (count < 3 || count > MAX_POINTS) return -1;
    for (size_t index = 0; index < length; ++index)
        if (values[index] < -2000 || values[index] > 2000) return -1;

    size_t order[MAX_POINTS], scratch[MAX_POINTS], upper[MAX_POINTS], lower[MAX_POINTS];
    for (size_t index = 0; index < count; ++index) order[index] = index;
    sort_indices(order, scratch, 0, count, values);
    for (size_t index = 1; index < count; ++index)
        if (values[2 * order[index - 1]] == values[2 * order[index]]) return -1;
    for (size_t index = 1; index + 1 < count; ++index)
        if (cross(order[0], order[index], order[count - 1], values) == 0) return -1;

    size_t upper_count = 1, lower_count = 1;
    upper[0] = lower[0] = 0;
    for (size_t index = 1; index < count; ++index) {
        const int turn = orientation(order[0], order[index], order[count - 1], values);
        if (index == count - 1 || turn != -1) {
            while (upper_count >= 2 &&
                   orientation(order[upper[upper_count - 2]], order[upper[upper_count - 1]],
                               order[index], values) == -1) --upper_count;
            upper[upper_count++] = index;
        }
        if (index == count - 1 || turn != 1) {
            while (lower_count >= 2 &&
                   orientation(order[lower[lower_count - 2]], order[lower[lower_count - 1]],
                               order[index], values) == 1) --lower_count;
            lower[lower_count++] = index;
        }
    }
    const size_t hull_count = upper_count - 2 + lower_count;
    if (output == NULL || output_capacity < 4 * hull_count) return -2;
    size_t written = 0;
    for (size_t index = 1; index + 1 < upper_count; ++index)
        put_index(output, written++, order[upper[index]]);
    for (size_t index = lower_count; index > 0; --index)
        put_index(output, written++, order[lower[index - 1]]);
    return (int64_t)hull_count;
}

#include <stddef.h>
#include <stdint.h>

static int middle_point(int first, int second) {
    if (first == second) return -1;
    const int first_x = first % 3;
    const int first_y = first / 3;
    const int second_x = second % 3;
    const int second_y = second / 3;
    const int delta_x = second_x - first_x;
    const int delta_y = second_y - first_y;
    if (delta_x % 2 != 0 || delta_y % 2 != 0) return -1;
    const int middle_x = (first_x + second_x) / 2;
    const int middle_y = (first_y + second_y) / 2;
    const int middle = middle_y * 3 + middle_x;
    return middle == first || middle == second ? -1 : middle;
}

static int64_t count_from(int last, uint16_t visited, int used, int target) {
    if (used == target) return 1;
    int64_t count = 0;
    for (int next = 0; next < 9; ++next) {
        const uint16_t bit = (uint16_t)(1u << (unsigned)next);
        if ((visited & bit) != 0) continue;
        const int middle = middle_point(last, next);
        if (middle >= 0 && (visited & (uint16_t)(1u << (unsigned)middle)) == 0)
            continue;
        count += count_from(next, (uint16_t)(visited | bit), used + 1, target);
    }
    return count;
}

int64_t android_unlock_pattern_count(const int64_t *input, size_t length) {
    if (input == NULL || length != 1) return -1;
    const int64_t target = input[0];
    if (target < 4 || target > 9) return -1;
    int64_t count = 0;
    for (int start = 0; start < 9; ++start)
        count += count_from(start, (uint16_t)(1u << (unsigned)start), 1, (int)target);
    return count;
}

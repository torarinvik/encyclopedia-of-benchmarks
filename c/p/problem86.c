#include <stdint.h>

#define MAX_LIMIT 1000000

static int is_square(int64_t value)
{
    int64_t root = value;
    int64_t next = (root + 1) / 2;
    while (next < root) {
        root = next;
        next = (root + value / root) / 2;
    }
    return root * root == value;
}

int64_t problem86(int64_t limit)
{
    if (limit > MAX_LIMIT) return -1;
    if (limit < 0) return 0;
    int64_t cuboid_count = 0;
    int64_t max_side = 0;
    while (cuboid_count <= limit) {
        ++max_side;
        for (int64_t sum_sides = 2; sum_sides <= 2 * max_side; ++sum_sides) {
            if (!is_square(sum_sides * sum_sides + max_side * max_side)) continue;
            int64_t high = max_side < sum_sides / 2 ? max_side : sum_sides / 2;
            int64_t low = sum_sides - max_side > 1 ? sum_sides - max_side : 1;
            cuboid_count += high - low + 1;
        }
    }
    return max_side;
}

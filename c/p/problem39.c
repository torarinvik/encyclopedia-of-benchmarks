/* Return the perimeter with the most integer right-triangle solutions. */
#include <stdint.h>

static int64_t integer_sqrt(int64_t value)
{
    int64_t low = 0;
    int64_t high = 1415;
    while (high - low > 1) {
        const int64_t middle = (low + high) / 2;
        if (middle * middle <= value) low = middle;
        else high = middle;
    }
    return low;
}

int64_t problem39(int64_t limit)
{
    if (limit < 12 || limit > 1000) return -1;
    int64_t counts[1001] = {0};
    int64_t first_order[1001] = {0};
    int64_t next_order = 1;
    for (int64_t base = 1; base <= limit; ++base) {
        for (int64_t perpendicular = base; perpendicular <= limit; ++perpendicular) {
            const int64_t square_sum = base * base + perpendicular * perpendicular;
            const int64_t hypotenuse = integer_sqrt(square_sum);
            if (hypotenuse * hypotenuse != square_sum) continue;
            const int64_t perimeter = base + perpendicular + hypotenuse;
            if (perimeter > limit) continue;
            if (counts[perimeter] == 0) first_order[perimeter] = next_order++;
            ++counts[perimeter];
        }
    }
    int64_t best_perimeter = -1;
    int64_t best_count = 0;
    int64_t best_order = INT64_MAX;
    for (int64_t perimeter = 1; perimeter <= limit; ++perimeter) {
        if (counts[perimeter] > 0 &&
            (counts[perimeter] > best_count ||
             (counts[perimeter] == best_count && first_order[perimeter] < best_order))) {
            best_perimeter = perimeter;
            best_count = counts[perimeter];
            best_order = first_order[perimeter];
        }
    }
    return best_perimeter;
}

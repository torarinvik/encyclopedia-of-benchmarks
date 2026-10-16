/* Return the perimeter with the most integer right-triangle solutions. */
#include <cstdint>
#include <limits>

namespace {
std::int64_t integer_sqrt(std::int64_t value) noexcept
{
    std::int64_t low = 0, high = 1415;
    while (high - low > 1) {
        const auto middle = (low + high) / 2;
        if (middle * middle <= value) low = middle;
        else high = middle;
    }
    return low;
}
}

extern "C" std::int64_t problem39(std::int64_t limit) noexcept
{
    if (limit < 12 || limit > 1000) return -1;
    std::int64_t counts[1001] = {};
    std::int64_t first_order[1001] = {};
    std::int64_t next_order = 1;
    for (std::int64_t base = 1; base <= limit; ++base) {
        for (std::int64_t perpendicular = base; perpendicular <= limit; ++perpendicular) {
            const auto square_sum = base * base + perpendicular * perpendicular;
            const auto hypotenuse = integer_sqrt(square_sum);
            if (hypotenuse * hypotenuse != square_sum) continue;
            const auto perimeter = base + perpendicular + hypotenuse;
            if (perimeter > limit) continue;
            if (counts[perimeter] == 0) first_order[perimeter] = next_order++;
            ++counts[perimeter];
        }
    }
    std::int64_t best_perimeter = -1, best_count = 0;
    auto best_order = std::numeric_limits<std::int64_t>::max();
    for (std::int64_t perimeter = 1; perimeter <= limit; ++perimeter) {
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

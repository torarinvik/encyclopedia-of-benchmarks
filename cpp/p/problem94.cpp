#include <cstdint>

extern "C" std::int64_t problem94(std::int64_t max_perimeter) noexcept
{
    if (max_perimeter < 0 || max_perimeter > 1'000'000'000) return -1;
    std::int64_t previous = 1;
    std::int64_t value = 2;
    std::int64_t perimeter_sum = 0;
    std::int64_t index = 0;
    std::int64_t perimeter = 0;
    while (perimeter <= max_perimeter) {
        perimeter_sum += perimeter;
        previous += 2 * value;
        value += previous;
        perimeter = index % 2 == 0 ? 2 * value + 2 : 2 * value - 2;
        ++index;
    }
    return perimeter_sum;
}

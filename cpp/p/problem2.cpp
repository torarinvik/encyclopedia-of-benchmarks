#include <cstdint>

extern "C" std::int64_t problem2(std::int64_t limit) noexcept
{
    if (limit < 0 || limit > 4'000'000) return -1;
    std::int64_t previous = 1;
    std::int64_t current = 2;
    std::int64_t sum = 0;
    while (current < limit) {
        if (current % 2 == 0) sum += current;
        const std::int64_t next = previous + current;
        previous = current;
        current = next;
    }
    return sum;
}

#include <cstdint>

extern "C" std::int64_t pell_number(std::int64_t index) noexcept
{
    if (index < 0 || index > 50) return -1;
    if (index == 0) return 0;
    std::int64_t previous = 0;
    std::int64_t current = 1;
    for (std::int64_t i = 2; i <= index; ++i) {
        const std::int64_t next = 2 * current + previous;
        previous = current;
        current = next;
    }
    return current;
}

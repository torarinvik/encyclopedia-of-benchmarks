/* Count ways to climb n stairs using one or two steps per move. */
#include <cstdint>

extern "C" std::int64_t climbing_stairs(std::int64_t steps) noexcept
{
    if (steps < 1 || steps > 45) return -1;
    std::int64_t previous = 1;
    std::int64_t current = 1;
    for (std::int64_t index = 2; index <= steps; ++index) {
        const std::int64_t next = previous + current;
        previous = current;
        current = next;
    }
    return current;
}

#include <cstdint>

extern "C" std::int64_t all_ones_sequence(std::int64_t index) noexcept
{
    return index < 0 ? -1 : 1;
}

#include <cstdint>

extern "C" std::int64_t all_twos_sequence(std::int64_t index) noexcept
{
    return index < 0 ? -1 : 2;
}

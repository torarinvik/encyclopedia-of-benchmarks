#include <cstdint>

extern "C" std::int64_t negative_integers_sequence(std::int64_t index) noexcept
{
    if (index < 0) return 0;
    return -index - 1;
}

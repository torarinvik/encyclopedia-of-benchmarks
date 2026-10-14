/* Sign of a signed 64-bit integer. */
#include <cstdint>

extern "C" std::int64_t signum(std::int64_t value) noexcept
{
    return static_cast<std::int64_t>(value > 0) - static_cast<std::int64_t>(value < 0);
}

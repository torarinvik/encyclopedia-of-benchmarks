// Return the logical complement on the Boolean 0/1 domain.
#include <cstdint>

extern "C" std::int64_t not_gate(std::int64_t value) noexcept
{
    return value == 0 ? 1 : 0;
}

#include <cstdint>

namespace {
constexpr std::int64_t max_index = 3037000499LL;
}

extern "C" std::int64_t squares_sequence(std::int64_t index) noexcept
{
    if (index < 0 || index > max_index) return -1;
    return index * index;
}

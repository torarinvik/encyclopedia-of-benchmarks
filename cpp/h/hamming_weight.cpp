#include <cstdint>

extern "C" std::int64_t hamming_weight(std::int64_t value) {
    if (value < 0 || static_cast<std::uint64_t>(value) > UINT32_MAX) return -1;
    return __builtin_popcount(static_cast<std::uint32_t>(value));
}

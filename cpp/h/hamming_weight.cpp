#include <cstdint>

extern "C" std::int64_t hamming_weight(std::int64_t value) {
    if (value < 0 || static_cast<std::uint64_t>(value) > UINT32_MAX) return -1;
    const std::uint32_t number = static_cast<std::uint32_t>(value);
    std::int64_t count = 0;
    for (unsigned bit = 0; bit < 32; ++bit)
        count += (number >> bit) & std::uint32_t{1};
    return count;
}

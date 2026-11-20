// Uncompiled indexed Calkin–Wilf fraction draft.
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t calkin_wilf_index(const std::int64_t* input, std::size_t length,
                                          std::uint8_t* output, std::size_t capacity) {
    if (!input || length != 1 || input[0] < 1 || input[0] >= (INT64_C(1) << 62)) return -1;
    if (!output || capacity < 16) return -2;
    const auto index = static_cast<std::uint64_t>(input[0]);
    std::uint64_t high = 1, numerator = 1, denominator = 1;
    while (high <= index / 2) high *= 2;
    for (high /= 2; high != 0; high /= 2) {
        if (index & high) numerator += denominator; else denominator += numerator;
    }
    for (std::size_t i = 0; i < 8; ++i) {
        output[i] = static_cast<std::uint8_t>(numerator >> (8*i));
        output[i+8] = static_cast<std::uint8_t>(denominator >> (8*i));
    }
    return 16;
}

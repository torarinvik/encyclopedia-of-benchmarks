#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <numeric>

extern "C" int64_t hyperloglog_raw_estimate(const int64_t *input, size_t length,
                                              uint8_t *output, size_t capacity) {
    if (!input || length < 1 || length > 130) return -1;
    const auto raw = input[0];
    if (raw < 0 || raw > 128 || length != static_cast<size_t>(raw)+1) return -1;
    std::array<uint8_t, 16> registers{};
    for (size_t i = 0; i < static_cast<size_t>(raw); ++i) {
        const auto value = input[i+1];
        if (value < 0 || static_cast<uint64_t>(value) > std::numeric_limits<uint32_t>::max()) return -1;
        const auto hash = static_cast<uint32_t>(value);
        const auto bucket = hash >> 28;
        const auto suffix = hash & UINT32_C(0x0fffffff);
        unsigned rank = 1;
        for (uint32_t mask = UINT32_C(1)<<27; mask && !(suffix & mask); mask >>= 1) ++rank;
        if (rank > registers[bucket]) registers[bucket] = static_cast<uint8_t>(rank);
    }
    uint64_t sum = 0;
    for (auto rank : registers) sum += UINT64_C(1) << (29-rank);
    uint64_t numerator = UINT64_C(673)*256*(UINT64_C(1)<<29), denominator = 1000*sum;
    const auto factor = std::gcd(numerator, denominator);
    numerator /= factor; denominator /= factor;
    if (!output || capacity < 144) return -2;
    std::array<uint64_t, 18> words{};
    words[0] = numerator; words[1] = denominator;
    for (size_t i = 0; i < 16; ++i) words[i+2] = registers[i];
    std::array<uint8_t, 144> staged{};
    for (size_t i = 0; i < 18; ++i)
        for (size_t b = 0; b < 8; ++b) staged[8*i+b] = static_cast<uint8_t>(words[i] >> (8*b));
    for (size_t i = 0; i < staged.size(); ++i) output[i] = staged[i];
    return 144;
}

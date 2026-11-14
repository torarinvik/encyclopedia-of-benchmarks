#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <limits>

extern "C" int64_t hyperloglog_corrected_estimate(const int64_t *input, size_t length,
                                                    uint8_t *output, size_t capacity) {
    if (!input || length < 1 || length > 130) return -1;
    const auto raw = input[0];
    if (raw < 0 || raw > 128 || length != static_cast<size_t>(raw)+1) return -1;
    std::array<unsigned, 16> registers{};
    for (size_t i = 0; i < static_cast<size_t>(raw); ++i) {
        const auto value = input[i+1];
        if (value < 0 || static_cast<uint64_t>(value) > std::numeric_limits<uint32_t>::max()) return -1;
        const auto hash = static_cast<uint32_t>(value);
        const auto bucket = hash >> 28, suffix = hash & UINT32_C(0x0fffffff);
        unsigned rank = 1;
        for (uint32_t mask = UINT32_C(1)<<27; mask && !(suffix & mask); mask >>= 1) ++rank;
        if (rank > registers[bucket]) registers[bucket] = rank;
    }
    uint64_t sum = 0;
    unsigned zeros = 0;
    for (auto rank : registers) { sum += UINT64_C(1) << (29-rank); if (!rank) ++zeros; }
    double estimate = (673.0*256.0*static_cast<double>(UINT64_C(1)<<29))/(1000.0*static_cast<double>(sum));
    constexpr double universe = 4294967296.0;
    if (estimate <= 40.0 && zeros) estimate = 16.0*std::log(16.0/zeros);
    else if (estimate > universe/30.0) {
        if (estimate >= universe) return -3;
        estimate = -universe*std::log1p(-estimate/universe);
    }
    if (!output || capacity < 8) return -2;
    uint64_t bits;
    std::memcpy(&bits, &estimate, sizeof bits);
    std::array<uint8_t, 8> staged{};
    for (size_t b = 0; b < 8; ++b) staged[b] = static_cast<uint8_t>(bits >> (8*b));
    for (size_t b = 0; b < 8; ++b) output[b] = staged[b];
    return 8;
}

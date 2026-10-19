#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_iterations = 1'125'000;
constexpr std::array<std::uint8_t, 16> nibble_bits = {
    0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4
};
constexpr std::array<std::uint32_t, 7> initial_seeds = {1, 1, 1, 1, 1, 1, 1};

int count_kernighan(std::uint32_t value) {
    int count = 0;
    while (value != 0) {
        value &= value - 1;
        ++count;
    }
    return count;
}

int count_parallel(std::uint32_t value) {
    value = ((value & 0xAAAAAAAAU) >> 1) + (value & 0x55555555U);
    value = ((value & 0xCCCCCCCCU) >> 2) + (value & 0x33333333U);
    value = ((value & 0xF0F0F0F0U) >> 4) + (value & 0x0F0F0F0FU);
    value = ((value & 0xFF00FF00U) >> 8) + (value & 0x00FF00FFU);
    value = ((value & 0xFFFF0000U) >> 16) + (value & 0x0000FFFFU);
    return static_cast<int>(value);
}

int count_recursive_nybbles(std::uint32_t value) {
    const int count = nibble_bits[value & 0xFU];
    return (value >> 4) == 0 ? count : count + count_recursive_nybbles(value >> 4);
}

int count_fixed_nybbles(std::uint32_t value) {
    int count = 0;
    for (unsigned shift = 0; shift < 32; shift += 4) count += nibble_bits[(value >> shift) & 0xFU];
    return count;
}

int count_byte(std::uint32_t value) {
    return nibble_bits[value & 0xFU] + nibble_bits[(value >> 4) & 0xFU];
}

int count_bw_bytes(std::uint32_t value) {
    return count_byte(value) + count_byte(value >> 8) +
           count_byte(value >> 24) + count_byte(value >> 16);
}

int count_ar_bytes(std::uint32_t value) {
    int count = 0;
    for (unsigned index = 0; index < 4; ++index) count += count_byte(value >> (index * 8));
    return count;
}

int count_shift_test(std::uint32_t value) {
    int count = 0;
    for (unsigned bit = 0; bit < 64 && value != 0; ++bit, value >>= 1) count += static_cast<int>(value & 1U);
    return count;
}

using Counter = int (*)(std::uint32_t);
constexpr std::array<Counter, 7> counters = {
    count_kernighan, count_parallel, count_recursive_nybbles,
    count_fixed_nybbles, count_bw_bytes, count_ar_bytes, count_shift_test
};
}

extern "C" std::int64_t cbench_automotive_bitcount(std::int64_t iterations) noexcept {
    if (iterations < 0 || iterations > max_iterations) return -1;
    std::int64_t result = 0;
    for (std::size_t algorithm = 0; algorithm < counters.size(); ++algorithm) {
        std::uint32_t seed = initial_seeds[algorithm];
        std::int64_t total = 0;
        for (std::int64_t iteration = 0; iteration < iterations; ++iteration, seed += 13)
            total += counters[algorithm](seed);
        result += static_cast<std::int64_t>(algorithm + 1) * total;
    }
    return result;
}

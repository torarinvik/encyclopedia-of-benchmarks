#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 10000;
void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t segmented_sieve(const std::int64_t *input, std::size_t length,
                                         std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length != 1 || input[0] < 2 || input[0] > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    std::size_t end = 0;
    while ((end + 1) * (end + 1) <= n) ++end;
    std::array<bool, 101> base_marks{};
    std::array<std::int64_t, 25> base{};
    std::size_t base_count = 0;
    for (std::size_t i = 2; i <= end; ++i) base_marks[i] = true;
    for (std::size_t p = 2; p <= end; ++p) {
        if (!base_marks[p]) continue;
        base[base_count++] = static_cast<std::int64_t>(p);
        for (std::size_t m = p * p; m <= end; m += p) base_marks[m] = false;
    }
    std::array<std::int64_t, 1229> primes{};
    std::size_t prime_count = 0;
    for (std::size_t i = 0; i < base_count; ++i) primes[prime_count++] = base[i];
    std::size_t low = end + 1;
    std::size_t high = 2 * end < n ? 2 * end : n;
    while (low <= n) {
        std::array<bool, 201> segment{};
        const auto segment_length = high - low + 1;
        for (std::size_t i = 0; i < segment_length; ++i) segment[i] = true;
        for (std::size_t i = 0; i < base_count; ++i) {
            const auto p = static_cast<std::size_t>(base[i]);
            auto first = (low / p) * p;
            if (first < low) first += p;
            for (auto m = first; m <= high; m += p) segment[m - low] = false;
        }
        for (std::size_t i = 0; i < segment_length; ++i) if (segment[i]) primes[prime_count++] = static_cast<std::int64_t>(low + i);
        low = high + 1;
        high = high + end < n ? high + end : n;
    }
    const auto output_length = prime_count * 8;
    if (capacity < output_length || (output_length > 0 && output == nullptr)) return -2;
    for (std::size_t i = 0; i < prime_count; ++i) put_i64_le(output, i * 8, primes[i]);
    return static_cast<std::int64_t>(output_length);
}

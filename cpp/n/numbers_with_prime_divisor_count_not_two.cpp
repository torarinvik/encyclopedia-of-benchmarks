#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxInputLength = 2;
constexpr std::size_t kMaxLimit = 1000;

bool is_prime_count(std::uint16_t value) noexcept {
    if (value < 2) return false;
    for (std::uint16_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return false;
    }
    return true;
}

void store_i64(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t numbers_with_prime_divisor_count_not_two(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > kMaxInputLength) return -1;
    if (length != 1 || input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxLimit)) return -1;

    const auto limit = static_cast<std::size_t>(input[0]);
    std::array<std::uint16_t, kMaxLimit> divisor_counts{};
    for (std::size_t divisor = 1; divisor < limit; ++divisor) {
        for (std::size_t multiple = divisor; multiple < limit; multiple += divisor)
            ++divisor_counts[multiple];
    }
    std::size_t selected_count = 0;
    for (std::size_t n = 1; n < limit; ++n) {
        const auto count = divisor_counts[n];
        if (count != 2 && is_prime_count(count)) ++selected_count;
    }
    const std::size_t output_bytes = selected_count * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::size_t output_index = 0;
    for (std::size_t n = 1; n < limit; ++n) {
        const auto count = divisor_counts[n];
        if (count != 2 && is_prime_count(count)) {
            store_i64(output, output_index * 8, static_cast<std::int64_t>(n));
            ++output_index;
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}

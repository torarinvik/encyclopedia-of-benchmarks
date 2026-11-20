#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxInputWords = 3;
constexpr std::int64_t kMaxStart = 4;
constexpr std::int64_t kMaxTransitions = 16;

std::int64_t small_power(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    for (std::int64_t index = 0; index < exponent; ++index) result *= base;
    return result;
}

std::int64_t rebase_hereditary(std::int64_t value, std::int64_t base,
                              std::int64_t raised_base) {
    if (value == 0) return 0;
    std::int64_t result = 0;
    std::int64_t place = 1;
    std::int64_t exponent = 0;
    while (place <= value) {
        const std::int64_t digit = (value / place) % base;
        if (digit != 0) {
            const auto raised_exponent = rebase_hereditary(exponent, base, raised_base);
            result += digit * small_power(raised_base, raised_exponent);
        }
        place *= base;
        ++exponent;
    }
    return result;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t goodstein_sequence_bounded_prefix(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > 3 || length != 2) return -1;
    const auto start = input[0];
    const auto transitions = input[1];
    if (start < 0 || start > kMaxStart || transitions < 0 || transitions > kMaxTransitions) return -1;

    std::array<std::int64_t, 17> terms{};
    std::size_t count = 1;
    terms[0] = start;
    auto current = start;
    std::int64_t base = 2;
    for (std::int64_t step = 0; step < transitions && current != 0; ++step) {
        current = rebase_hereditary(current, base, base + 1) - 1;
        ++base;
        terms[count++] = current;
    }

    const std::size_t output_bytes = (count + 1) * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    store_i64_le(output, 0, static_cast<std::int64_t>(count));
    for (std::size_t index = 0; index < count; ++index)
        store_i64_le(output, (index + 1) * 8, terms[index]);
    return static_cast<std::int64_t>(output_bytes);
}

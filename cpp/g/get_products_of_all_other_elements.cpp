#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxArrayLength = 32;
constexpr std::size_t kMaxInputLength = 34;

void write_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
}
}

extern "C" std::int64_t get_products_of_all_other_elements(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > kMaxInputLength) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(kMaxArrayLength)) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;
    std::int64_t result[kMaxArrayLength]{};
    for (std::size_t i = 0; i < n; ++i) {
        if (input[i + 1] < -2 || input[i + 1] > 2) return -1;
    }
    if (n < 2) return 0;
    const std::size_t output_bytes = n * 8;
    if (output == nullptr || capacity < output_bytes) return -2;

    result[0] = 1;
    for (std::size_t i = 0; i < n - 1; ++i) result[i + 1] = input[i + 1] * result[i];
    std::int64_t suffix = 1;
    for (std::size_t i = n - 1; i > 0; --i) {
        const std::int64_t value = input[i + 1];
        result[i - 1] *= suffix * value;
        suffix *= value;
    }
    for (std::size_t i = 0; i < n; ++i) write_i64_le(output, i * 8, result[i]);
    return static_cast<std::int64_t>(output_bytes);
}

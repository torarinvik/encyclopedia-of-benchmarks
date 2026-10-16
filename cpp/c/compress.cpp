#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 64;
constexpr std::size_t bytes_per_value = 4;

void store_i32_le(std::uint8_t *output, std::size_t position, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(value));
    for (std::size_t byte = 0; byte < bytes_per_value; ++byte)
        output[position + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}  // namespace

extern "C" std::int64_t compress(const std::int64_t *input, std::size_t length,
                                 std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 1 || length > max_length + 1) return -1;
    const auto count_value = input[0];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(max_length)
        || length != 1 + static_cast<std::size_t>(count_value)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    for (std::size_t index = 0; index < count; ++index)
        if (input[1 + index] < INT32_MIN || input[1 + index] > INT32_MAX) return -1;

    const auto maximum_bytes = count * bytes_per_value;
    if (output_capacity < maximum_bytes || (maximum_bytes > 0 && output == nullptr)) return -2;
    std::size_t result_count = 0;
    std::int64_t previous = 0;
    for (std::size_t index = 0; index < count; ++index) {
        const auto value = input[1 + index];
        if (index == 0 || value != previous) {
            store_i32_le(output, result_count * bytes_per_value, value);
            ++result_count;
        }
        previous = value;
    }
    return static_cast<std::int64_t>(result_count);
}

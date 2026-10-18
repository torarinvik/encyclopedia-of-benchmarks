/* Replay reverse Fisher-Yates or the Ruby half-interleave variant. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 32;
constexpr std::size_t kMaxParseableInputLength = 67;
constexpr std::size_t kMaxOutputBytes = 520;
constexpr std::int64_t kI32Min = -2'147'483'648LL;
constexpr std::int64_t kI32Max = 2'147'483'647LL;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t shuffle_array(const std::int64_t *input, std::size_t input_length,
                                       std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || input_length < 2 || input_length > kMaxParseableInputLength) return -1;
    const std::int64_t variant = input[0];
    const std::int64_t n_value = input[1];
    if ((variant != 0 && variant != 1) || n_value < 0 || n_value > static_cast<std::int64_t>(kMaxN)) return -1;
    const std::size_t n = static_cast<std::size_t>(n_value);
    const std::size_t value_count = variant == 0 ? n : 2 * n;
    const std::size_t draw_count = variant == 0 && n > 0 ? n - 1 : 0;
    if (input_length != 2 + value_count + draw_count) return -1;

    std::array<std::int64_t, 2 * kMaxN> result_values{};
    const std::size_t result_count = value_count;
    for (std::size_t index = 0; index < value_count; ++index) {
        const std::int64_t value = input[2 + index];
        if (value < kI32Min || value > kI32Max) return -1;
        result_values[index] = value;
    }

    if (variant == 0) {
        for (std::size_t draw_index = 0; draw_index < draw_count; ++draw_index) {
            const std::size_t current_index = n - 1 - draw_index;
            const std::int64_t chosen_value = input[2 + n + draw_index];
            if (chosen_value < 0 || chosen_value > static_cast<std::int64_t>(current_index)) return -1;
            const std::size_t chosen_index = static_cast<std::size_t>(chosen_value);
            const std::int64_t temporary = result_values[current_index];
            result_values[current_index] = result_values[chosen_index];
            result_values[chosen_index] = temporary;
        }
    } else {
        for (std::size_t index = 0; index < n; ++index) {
            result_values[2 * index] = input[2 + index];
            result_values[2 * index + 1] = input[2 + n + index];
        }
    }

    const std::size_t output_bytes = 8 * (result_count + 1);
    if (output_bytes > kMaxOutputBytes || output == nullptr || output_capacity < output_bytes) return -2;
    store_i64_le(output, 0, static_cast<std::int64_t>(result_count));
    for (std::size_t index = 0; index < result_count; ++index)
        store_i64_le(output, 8 * (index + 1), result_values[index]);
    return static_cast<std::int64_t>(output_bytes);
}

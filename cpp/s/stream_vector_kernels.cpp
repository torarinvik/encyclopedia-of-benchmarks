#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_count = 128;
constexpr std::size_t max_input_length = 259;

void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t stream_vector_kernels(const std::int64_t *input, std::size_t length,
                                                std::uint8_t *output,
                                                std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const auto mode = input[0];
    const auto count_value = input[1];
    if (mode < 0 || mode > 3 || count_value < 0 || count_value > static_cast<std::int64_t>(max_count)) return -1;

    const auto count = static_cast<std::size_t>(count_value);
    const bool has_alpha = mode == 1 || mode == 3;
    const std::size_t array_count = mode == 0 || mode == 1 ? 1u : 2u;
    if (length != 2u + static_cast<std::size_t>(has_alpha) + array_count * count) return -1;

    std::size_t a_start = 2;
    std::int64_t alpha = 0;
    if (has_alpha) {
        alpha = input[2];
        if (alpha < -1000 || alpha > 1000) return -1;
        a_start = 3;
    }
    const auto b_start = a_start + count;
    for (std::size_t index = 0; index < array_count * count; ++index)
        if (input[a_start + index] < -1000 || input[a_start + index] > 1000) return -1;

    std::int64_t staged[max_count]{};
    for (std::size_t index = 0; index < count; ++index) {
        const auto a = input[a_start + index];
        std::int64_t value;
        if (mode == 0) value = a;
        else if (mode == 1) value = alpha * a;
        else if (mode == 2) value = a + input[b_start + index];
        else value = a + alpha * input[b_start + index];
        // Bounded operands keep every multiplication and sum inside int64.
        staged[index] = value;
    }

    const std::size_t output_bytes = count * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < count; ++index)
        write_i64_le(output, index * 8, staged[index]);
    return static_cast<std::int64_t>(output_bytes);
}

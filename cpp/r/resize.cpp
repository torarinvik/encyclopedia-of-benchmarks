#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 3077;
constexpr std::size_t max_output_bytes = 3072;
}

extern "C" std::int64_t resize(const std::int64_t *input, std::size_t length,
                                std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > max_input_length) return -1;

    const auto src_width = input[0];
    const auto src_height = input[1];
    const auto dst_width = input[2];
    const auto dst_height = input[3];
    if (src_width < 1 || src_width > 32 || src_height < 1 || src_height > 32 ||
        dst_width < 1 || dst_width > 32 || dst_height < 1 || dst_height > 32) return -1;

    const std::size_t expected_length = 4 + 3 * static_cast<std::size_t>(src_width) *
                                            static_cast<std::size_t>(src_height);
    if (length != expected_length) return -1;
    for (std::size_t i = 4; i < expected_length; ++i) {
        if (input[i] < 0 || input[i] > 255) return -1;
    }

    const std::size_t needed = 3 * static_cast<std::size_t>(dst_width) *
                               static_cast<std::size_t>(dst_height);
    if (needed > max_output_bytes) return -1;
    if (output == nullptr || capacity < needed) return -2;

    const double ratio_x = static_cast<double>(src_width) / static_cast<double>(dst_width);
    const double ratio_y = static_cast<double>(src_height) / static_cast<double>(dst_height);
    std::size_t out = 0;
    for (std::size_t y = 0; y < static_cast<std::size_t>(dst_height); ++y) {
        const auto src_y = static_cast<std::size_t>(ratio_y * static_cast<double>(y));
        for (std::size_t x = 0; x < static_cast<std::size_t>(dst_width); ++x) {
            const auto src_x = static_cast<std::size_t>(ratio_x * static_cast<double>(x));
            const std::size_t src = 4 + 3 * (src_y * static_cast<std::size_t>(src_width) + src_x);
            output[out++] = static_cast<std::uint8_t>(input[src]);
            output[out++] = static_cast<std::uint8_t>(input[src + 1]);
            output[out++] = static_cast<std::uint8_t>(input[src + 2]);
        }
    }
    return static_cast<std::int64_t>(needed);
}

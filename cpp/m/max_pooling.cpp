#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::int32_t max_n = 16;
constexpr std::size_t max_input_words = 3 + max_n * max_n;
constexpr std::size_t max_parseable_input_words = max_input_words + 1;
constexpr std::size_t max_output_bytes = 8 * max_n * max_n;
}

extern "C" std::int64_t max_pooling(const std::int32_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > max_parseable_input_words) return -1;
    const auto n = input[0], size = input[1], stride = input[2];
    if (n < 1 || n > max_n || size < 1 || size > n || stride < 1 || stride > max_n ||
        length != 3 + static_cast<std::size_t>(n) * static_cast<std::size_t>(n)) return -1;
    const auto cells = static_cast<std::size_t>(n) * static_cast<std::size_t>(n);
    for (std::size_t i = 0; i < cells; ++i) if (input[3 + i] < -1000000 || input[3 + i] > 1000000) return -1;
    const auto out_side = (n - size) / stride + 1;
    const auto output_count = static_cast<std::size_t>(out_side) * static_cast<std::size_t>(out_side);
    const auto bytes = output_count * 8;
    if (output == nullptr || capacity < bytes) return -2;
    std::uint8_t buffer[max_output_bytes];
    std::size_t position = 0;
    for (std::int32_t row = 0; row < out_side; ++row) {
        for (std::int32_t col = 0; col < out_side; ++col) {
            const auto start_row = row * stride, start_col = col * stride;
            auto maximum = input[3 + static_cast<std::size_t>(start_row) * n + start_col];
            for (std::int32_t r = 0; r < size; ++r) for (std::int32_t c = 0; c < size; ++c) {
                const auto value = input[3 + static_cast<std::size_t>(start_row + r) * n + start_col + c];
                if (value > maximum) maximum = value;
            }
            const double result = static_cast<double>(maximum);
            std::uint64_t bits;
            std::memcpy(&bits, &result, sizeof(bits));
            for (std::size_t byte = 0; byte < 8; ++byte) buffer[position++] = static_cast<std::uint8_t>(bits >> (8 * byte));
        }
    }
    for (std::size_t i = 0; i < bytes; ++i) output[i] = buffer[i];
    return static_cast<std::int64_t>(bytes);
}

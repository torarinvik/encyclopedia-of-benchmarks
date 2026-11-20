/* Integer-only, four-normal Hough accumulator for an 8 by 8 binary grid. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxHeight = 8;
constexpr std::int64_t kMaxWidth = 8;
constexpr std::size_t kMaxParseableInputLength = 67;
constexpr std::size_t kRhoCount = 29;
constexpr std::size_t kOutputBytes = 116;
} // namespace

extern "C" std::int64_t hough_line_transform(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 3 || length > kMaxParseableInputLength) return -1;
    const std::int64_t height_value = input[0];
    const std::int64_t width_value = input[1];
    if (height_value < 1 || height_value > kMaxHeight ||
        width_value < 1 || width_value > kMaxWidth) return -1;
    const auto height = static_cast<std::size_t>(height_value);
    const auto width = static_cast<std::size_t>(width_value);
    const std::size_t cells = height * width;
    if (length != 2 + cells) return -1;
    for (std::size_t index = 0; index < cells; ++index) {
        if (input[index + 2] != 0 && input[index + 2] != 1) return -1;
    }
    if (output == nullptr || output_capacity < kOutputBytes) return -2;

    std::array<std::uint8_t, kOutputBytes> accumulator{};
    for (std::size_t row = 0; row < height; ++row) {
        for (std::size_t column = 0; column < width; ++column) {
            if (input[2 + row * width + column] == 0) continue;
            const auto x = static_cast<std::int64_t>(column);
            const auto y = static_cast<std::int64_t>(row);
            const std::array<std::int64_t, 4> rho{x, x + y, y, -x + y};
            for (std::size_t angle = 0; angle < rho.size(); ++angle) {
                const auto bin = angle * kRhoCount + static_cast<std::size_t>(rho[angle] + 14);
                ++accumulator[bin];
            }
        }
    }
    for (std::size_t index = 0; index < kOutputBytes; ++index) output[index] = accumulator[index];
    return static_cast<std::int64_t>(kOutputBytes);
}

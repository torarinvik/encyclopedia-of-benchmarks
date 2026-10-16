#include <cstddef>
#include <cstdint>

static constexpr std::int64_t MAX_SIDE_LENGTH = 32;
static constexpr std::size_t MAX_PARSEABLE_INPUT_LENGTH = 1026;

extern "C" std::int64_t mean_threshold(const std::int64_t *input, std::size_t length,
                                       std::uint8_t *output,
                                       std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_SIDE_LENGTH) return -1;

    const auto side = static_cast<std::size_t>(input[0]);
    const std::size_t pixel_count = side * side;
    if (length != pixel_count + 1) return -1;

    std::int64_t sum = 0;
    for (std::size_t i = 0; i < pixel_count; ++i) {
        const std::int64_t pixel = input[1 + i];
        if (pixel < 0 || pixel > 255) return -1;
        sum += pixel;
    }

    const std::int64_t mean = sum / static_cast<std::int64_t>(pixel_count);
    if (output_capacity < pixel_count || output == nullptr) return -2;
    for (std::size_t i = 0; i < pixel_count; ++i)
        output[i] = input[1 + i] > mean ? 255 : 0;
    return static_cast<std::int64_t>(pixel_count);
}


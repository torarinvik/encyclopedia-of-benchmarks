// Independently written bounded IJG h2v2 adaptation; see package README/LICENSE.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t cbench_consumer_jpeg_h2v2_fancy_upsample(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity)
{
    if (input == nullptr || length < 5 || length > 131) return -1;
    if (input[0] < 3 || input[0] > 16 || input[1] < 1 || input[1] > 8) return -1;
    const auto width = static_cast<std::size_t>(input[0]);
    const auto height = static_cast<std::size_t>(input[1]);
    const auto pixels = width * height;
    if (length != 2 + pixels) return -1;
    for (std::size_t i = 0; i < pixels; ++i) if (input[i + 2] < 0 || input[i + 2] > 255) return -1;
    const std::size_t output_size = 4 * pixels;
    if (output == nullptr || capacity < output_size) return -2;
    std::uint8_t staged[512]{};
    std::size_t p = 0;
    for (std::size_t y = 0; y < height; ++y) for (int v = 0; v < 2; ++v) {
        const auto far_y = v == 0 ? (y == 0 ? 0 : y - 1) : (y + 1 == height ? y : y + 1);
        int sums[16]{};
        for (std::size_t x = 0; x < width; ++x)
            sums[x] = 3 * static_cast<int>(input[2 + y * width + x]) + static_cast<int>(input[2 + far_y * width + x]);
        staged[p++] = static_cast<std::uint8_t>((sums[0] * 4 + 8) >> 4);
        staged[p++] = static_cast<std::uint8_t>((sums[0] * 3 + sums[1] + 7) >> 4);
        for (std::size_t x = 1; x + 1 < width; ++x) {
            staged[p++] = static_cast<std::uint8_t>((sums[x] * 3 + sums[x - 1] + 8) >> 4);
            staged[p++] = static_cast<std::uint8_t>((sums[x] * 3 + sums[x + 1] + 7) >> 4);
        }
        staged[p++] = static_cast<std::uint8_t>((sums[width - 1] * 3 + sums[width - 2] + 8) >> 4);
        staged[p++] = static_cast<std::uint8_t>((sums[width - 1] * 4 + 7) >> 4);
    }
    for (std::size_t i = 0; i < output_size; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(output_size);
}

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t MinSide = 3;
constexpr std::size_t MaxSide = 16;
constexpr std::size_t MaxParseableInputLength = 258;
constexpr std::size_t MaxOutputElements = 512;
constexpr std::size_t MaxOutputBytes = 4096;
constexpr int KernelX[9] = {-1, 0, 1, -2, 0, 2, -1, 0, 1};
constexpr int KernelY[9] = {1, 2, 1, 0, 0, 0, -1, -2, -1};

void write_f64_le(std::uint8_t* output, std::size_t offset, double value)
{
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (unsigned int byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffu);
        bits >>= 8u;
    }
}
}

extern "C" std::int64_t sobel_filter(const std::int64_t* input, std::size_t input_length,
                                      std::uint8_t* output, std::size_t capacity)
{
    if (input == nullptr || input_length < 2 || input_length > MaxParseableInputLength) return -1;
    if (input[0] < static_cast<std::int64_t>(MinSide) || input[0] > static_cast<std::int64_t>(MaxSide)) return -1;
    const std::size_t side = static_cast<std::size_t>(input[0]);
    const std::size_t pixel_count = side * side;
    if (input_length != pixel_count + 1) return -1;
    std::array<int, MaxSide * MaxSide> image{};
    for (std::size_t index = 0; index < pixel_count; ++index) {
        if (input[index + 1] < 0 || input[index + 1] > 255) return -1;
        image[index] = static_cast<int>(input[index + 1]);
    }

    std::array<int, MaxSide * MaxSide> gradient_x{};
    std::array<int, MaxSide * MaxSide> gradient_y{};
    int max_x = 0;
    int max_y = 0;
    for (std::size_t y = 0; y < side; ++y) {
        for (std::size_t x = 0; x < side; ++x) {
            int gx = 0;
            int gy = 0;
            for (int ky = 0; ky < 3; ++ky) {
                const int sample_y = std::clamp(static_cast<int>(y) + ky - 1, 0, static_cast<int>(side) - 1);
                for (int kx = 0; kx < 3; ++kx) {
                    const int sample_x = std::clamp(static_cast<int>(x) + kx - 1, 0, static_cast<int>(side) - 1);
                    const int pixel = image[static_cast<std::size_t>(sample_y) * side + static_cast<std::size_t>(sample_x)];
                    const std::size_t kernel_index = static_cast<std::size_t>(ky * 3 + kx);
                    gx += pixel * KernelX[kernel_index];
                    gy += pixel * KernelY[kernel_index];
                }
            }
            gx = std::abs(gx);
            gy = std::abs(gy);
            const std::size_t index = y * side + x;
            gradient_x[index] = gx;
            gradient_y[index] = gy;
            max_x = std::max(max_x, gx);
            max_y = std::max(max_y, gy);
        }
    }
    if (max_x == 0 || max_y == 0) return -1;

    std::array<double, MaxSide * MaxSide> scaled_x{};
    std::array<double, MaxSide * MaxSide> scaled_y{};
    std::array<double, MaxSide * MaxSide> magnitude{};
    std::array<double, MaxSide * MaxSide> theta{};
    double max_magnitude = 0.0;
    for (std::size_t index = 0; index < pixel_count; ++index) {
        scaled_x[index] = (static_cast<double>(gradient_x[index]) * 255.0) / static_cast<double>(max_x);
        scaled_y[index] = (static_cast<double>(gradient_y[index]) * 255.0) / static_cast<double>(max_y);
        magnitude[index] = std::sqrt((scaled_x[index] * scaled_x[index]) + (scaled_y[index] * scaled_y[index]));
        max_magnitude = std::max(max_magnitude, magnitude[index]);
    }
    if (max_magnitude == 0.0) return -1;
    for (std::size_t index = 0; index < pixel_count; ++index) {
        const double normalized = (magnitude[index] * 255.0) / max_magnitude;
        magnitude[index] = static_cast<double>(static_cast<std::uint8_t>(normalized));
        theta[index] = std::atan2(scaled_y[index], scaled_x[index]);
    }

    const std::size_t output_elements = 2 * pixel_count;
    const std::size_t output_bytes = output_elements * 8;
    if (output_elements > MaxOutputElements || output_bytes > MaxOutputBytes) return -1;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < pixel_count; ++index) {
        write_f64_le(output, index * 8, magnitude[index]);
        write_f64_le(output, (pixel_count + index) * 8, theta[index]);
    }
    return static_cast<std::int64_t>(output_elements);
}

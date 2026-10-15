#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) { output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffu); bits >>= 8; }
}
std::int64_t quantize(double value) {
    const double scaled = value * 1000000.0;
    return static_cast<std::int64_t>(scaled >= 0.0 ? scaled + 0.5 : scaled - 0.5);
}
void transform(double real[64], double imag[64], std::size_t n) {
    std::size_t reverse = 0;
    for (std::size_t position = 1; position < n; ++position) {
        std::size_t bit = n >> 1;
        while ((reverse & bit) != 0) { reverse ^= bit; bit >>= 1; }
        reverse ^= bit;
        if (position < reverse) { double temporary = real[position]; real[position] = real[reverse]; real[reverse] = temporary; temporary = imag[position]; imag[position] = imag[reverse]; imag[reverse] = temporary; }
    }
    for (std::size_t block = 2; block <= n; block *= 2) {
        const double angle = 6.283185307179586476925286766559 / static_cast<double>(block);
        const double step_real = std::cos(angle), step_imag = -std::sin(angle);
        for (std::size_t start = 0; start < n; start += block) {
            double weight_real = 1.0, weight_imag = 0.0;
            for (std::size_t offset = 0; offset < block / 2; ++offset) {
                const std::size_t first = start + offset, second = first + block / 2;
                const double product_real = weight_real * real[second] - weight_imag * imag[second];
                const double product_imag = weight_real * imag[second] + weight_imag * real[second];
                const double first_real = real[first], first_imag = imag[first];
                real[first] = first_real + product_real; imag[first] = first_imag + product_imag;
                real[second] = first_real - product_real; imag[second] = first_imag - product_imag;
                const double next_real = weight_real * step_real - weight_imag * step_imag;
                weight_imag = weight_real * step_imag + weight_imag * step_real; weight_real = next_real;
            }
        }
    }
}
}

extern "C" std::int64_t inverse_fast_fourier_transform(const std::int64_t* values, std::size_t length,
                                                 std::uint8_t* output, std::size_t capacity) noexcept {
    if (values == nullptr || length < 3 || length > 129) return -1;
    const std::int64_t raw_n = values[0];
    if (raw_n < 1 || raw_n > 64 || (raw_n & (raw_n - 1)) != 0 || length != 1 + 2 * static_cast<std::size_t>(raw_n)) return -1;
    const std::size_t n = static_cast<std::size_t>(raw_n);
    for (std::size_t index = 0; index < 2 * n; ++index) if (values[index + 1] < -1000 || values[index + 1] > 1000) return -1;
    const std::size_t byte_count = 8 * n;
    if (output == nullptr || capacity < byte_count) return -2;
    double real[64] = {}, imag[64] = {};
    for (std::size_t index = 0; index < n; ++index) { real[index] = static_cast<double>(values[2 * index + 1]); imag[index] = static_cast<double>(values[2 * index + 2]); }
    transform(real, imag, n);
    for (std::size_t index = 0; index < n; ++index) store_i64_le(output, 8 * index, quantize(real[index] / static_cast<double>(n)));
    return static_cast<std::int64_t>(byte_count);
}

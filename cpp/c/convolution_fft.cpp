#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t max_signal_length = 64, max_input_length = 2 + 2 * max_signal_length + 1;
constexpr std::size_t max_fft_length = 2 * max_signal_length;
constexpr double sample_scale = 16.0, pi = 3.14159265358979323846264338327950288;
struct Complex { double real, imag; };
void write_f64_le(std::uint8_t* output, std::size_t offset, double value) {
    std::uint64_t bits; std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
void fft(Complex* values, std::size_t n, bool inverse) {
    std::size_t reverse = 0;
    for (std::size_t position = 1; position < n; ++position) {
        std::size_t bit = n >> 1;
        while ((reverse & bit) != 0) { reverse ^= bit; bit >>= 1; }
        reverse ^= bit;
        if (position < reverse) { const Complex temporary = values[position]; values[position] = values[reverse]; values[reverse] = temporary; }
    }
    for (std::size_t block = 2; block <= n; block *= 2) {
        const double direction = inverse ? -1.0 : 1.0;
        const double angle = -2.0 * pi / static_cast<double>(block) * direction;
        const double step_real = std::cos(angle), step_imag = std::sin(angle);
        for (std::size_t start = 0; start < n; start += block) {
            double weight_real = 1.0, weight_imag = 0.0;
            for (std::size_t offset = 0; offset < block / 2; ++offset) {
                const std::size_t first = start + offset, second = first + block / 2;
                const double product_real = weight_real * values[second].real - weight_imag * values[second].imag;
                const double product_imag = weight_real * values[second].imag + weight_imag * values[second].real;
                const double first_real = values[first].real, first_imag = values[first].imag;
                values[first] = {first_real + product_real, first_imag + product_imag};
                values[second] = {first_real - product_real, first_imag - product_imag};
                const double next_real = weight_real * step_real - weight_imag * step_imag;
                weight_imag = weight_real * step_imag + weight_imag * step_real; weight_real = next_real;
            }
        }
    }
    if (inverse) for (std::size_t index = 0; index < n; ++index) { values[index].real /= static_cast<double>(n); values[index].imag /= static_cast<double>(n); }
}
}

extern "C" std::int64_t convolution_fft(const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > max_input_length) return -1;
    const auto raw_a_count = input[0], raw_b_count = input[1];
    if (raw_a_count < 1 || raw_a_count > 64 || raw_b_count < 1 || raw_b_count > 64) return -1;
    const auto a_count = static_cast<std::size_t>(raw_a_count), b_count = static_cast<std::size_t>(raw_b_count);
    if (length != 2 + a_count + b_count) return -1;
    for (std::size_t index = 0; index < a_count + b_count; ++index) if (input[index + 2] < -64 || input[index + 2] > 64) return -1;
    const auto result_count = a_count + b_count - 1, byte_count = result_count * 16;
    if (output == nullptr || capacity < byte_count) return -2;
    std::size_t fft_length = 1; while (fft_length < result_count) fft_length *= 2;
    Complex a[max_fft_length]{}, b[max_fft_length]{}, product[max_fft_length]{};
    for (std::size_t index = 0; index < a_count; ++index) a[index].real = static_cast<double>(input[index + 2]) / sample_scale;
    for (std::size_t index = 0; index < b_count; ++index) b[index].real = static_cast<double>(input[a_count + index + 2]) / sample_scale;
    fft(a, fft_length, false); fft(b, fft_length, false);
    for (std::size_t index = 0; index < fft_length; ++index) product[index] = {
        a[index].real * b[index].real - a[index].imag * b[index].imag,
        a[index].real * b[index].imag + a[index].imag * b[index].real};
    fft(product, fft_length, true);
    for (std::size_t index = 0; index < result_count; ++index) {
        write_f64_le(output, index * 16, product[index].real); write_f64_le(output, index * 16 + 8, product[index].imag);
    }
    return static_cast<std::int64_t>(byte_count);
}

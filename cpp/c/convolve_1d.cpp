#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t max_signal_length = 64;
constexpr std::size_t max_input_length = 2 + 2 * max_signal_length;
constexpr std::size_t max_output_bytes = max_signal_length * 8;
constexpr std::int64_t max_fixed_sample = 128;
constexpr double sample_scale = 16.0;

void write_f64_le(std::uint8_t* output, std::size_t offset, double value) noexcept {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t convolve_1d(const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const auto raw_signal_count = input[0];
    const auto raw_kernel_count = input[1];
    if (raw_signal_count < 0 || raw_signal_count > static_cast<std::int64_t>(max_signal_length) ||
        raw_kernel_count < 0 || raw_kernel_count > static_cast<std::int64_t>(max_signal_length)) return -1;
    const auto signal_count = static_cast<std::size_t>(raw_signal_count);
    const auto kernel_count = static_cast<std::size_t>(raw_kernel_count);
    if (length != 2 + signal_count + kernel_count) return -1;
    for (std::size_t index = 0; index < signal_count + kernel_count; ++index) {
        if (input[index + 2] < -max_fixed_sample || input[index + 2] > max_fixed_sample) return -1;
    }

    const auto output_bytes = signal_count * 8;
    if (output_capacity < output_bytes || (output_bytes > 0 && output == nullptr)) return -2;
    const auto center = kernel_count / 2;
    for (std::size_t i = 0; i < signal_count; ++i) {
        double accumulated = 0.0;
        for (std::size_t j = 0; j < kernel_count; ++j) {
            const auto signal_index = static_cast<std::int64_t>(i) + static_cast<std::int64_t>(j)
                - static_cast<std::int64_t>(center);
            if (signal_index >= 0 && signal_index < static_cast<std::int64_t>(signal_count)) {
                const double kernel_value = static_cast<double>(input[2 + signal_count + j]) / sample_scale;
                const double signal_value = static_cast<double>(input[2 + static_cast<std::size_t>(signal_index)]) / sample_scale;
                accumulated += kernel_value * signal_value;
            }
        }
        write_f64_le(output, i * 8, accumulated);
    }
    return static_cast<std::int64_t>(output_bytes);
}

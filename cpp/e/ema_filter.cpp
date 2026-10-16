/* Apply the bounded Java EMAFilter recurrence to an integer sample stream. */
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
void put_f64_le(std::uint8_t *output, std::size_t offset, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t ema_filter(const std::int64_t *input, std::size_t length,
                                    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 2 || length > 7) return -1;
    const std::int64_t alpha_units = input[0], count_value = input[1];
    if (alpha_units < 1 || alpha_units > 1024 || count_value < 0 || count_value > 4 ||
        length != 2 + static_cast<std::size_t>(count_value)) return -1;
    const std::size_t count = static_cast<std::size_t>(count_value);
    for (std::size_t index = 0; index < count; ++index)
        if (input[index + 2] < -1000000 || input[index + 2] > 1000000) return -1;
    const std::size_t required = count * 8;
    if (output_capacity < required || (required > 0 && output == nullptr)) return -2;

    const double alpha = static_cast<double>(alpha_units) / 1024.0;
    double ema_value = 0.0;
    for (std::size_t index = 0; index < count; ++index) {
        const double sample = static_cast<double>(input[index + 2]);
        if (index == 0) ema_value = sample;
        else ema_value = alpha * sample + (1.0 - alpha) * ema_value;
        put_f64_le(output, index * 8, ema_value);
    }
    return static_cast<std::int64_t>(required);
}

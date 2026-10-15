#include <cstddef>
#include <cstdint>

extern "C" std::int64_t circular_convolution(const std::int64_t* values, std::size_t length,
                                                std::uint8_t* output, std::size_t capacity) {
    if (values == nullptr || length < 4) return -1;
    const std::int64_t raw_a_length = values[0];
    const std::int64_t raw_b_length = values[1];
    if (raw_a_length < 1 || raw_a_length > 8 || raw_b_length < 1 || raw_b_length > 8) return -1;
    const std::size_t a_length = static_cast<std::size_t>(raw_a_length);
    const std::size_t b_length = static_cast<std::size_t>(raw_b_length);
    if (length != 2 + a_length + b_length) return -1;
    for (std::size_t i = 0; i < a_length + b_length; ++i) {
        if (values[2 + i] < -2 || values[2 + i] > 2) return -1;
    }
    const std::size_t n = a_length > b_length ? a_length : b_length;
    if (output == nullptr || capacity < n) return -2;

    for (std::size_t k = 0; k < n; ++k) {
        std::int64_t sum = 0;
        for (std::size_t i = 0; i < n; ++i) {
            const std::size_t b_index = (k + n - i) % n;
            const std::int64_t a_value = i < a_length ? values[2 + i] : 0;
            const std::int64_t b_value = b_index < b_length ? values[2 + a_length + b_index] : 0;
            sum += a_value * b_value;
        }
        output[k] = static_cast<std::uint8_t>(sum < 0 ? sum + 256 : sum);
    }
    return static_cast<std::int64_t>(n);
}

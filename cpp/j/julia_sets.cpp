#include <cstddef>
#include <cstdint>
#include <cstring>

static void put_f32_le(std::uint8_t *output, std::size_t offset, float value) {
    std::uint32_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

extern "C" std::int64_t julia_sets(const std::int64_t *input, std::size_t length,
                                    std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 4 || length > 68) return -1;
    const auto iterations = input[0], cr_units = input[1], ci_units = input[2], count_value = input[3];
    if (iterations < 0 || iterations > 8 || count_value < 0 || count_value > 32 ||
        cr_units < -128 || cr_units > 128 || ci_units < -128 || ci_units > 128) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 4 + 2 * count) return -1;
    for (std::size_t i = 0; i < 2 * count; ++i)
        if (input[4 + i] < -128 || input[4 + i] > 128) return -1;
    const std::size_t needed = 8 * count;
    if (output == nullptr || capacity < needed) return -2;

    const float cr = static_cast<float>(cr_units) / 16.0f;
    const float ci = static_cast<float>(ci_units) / 16.0f;
    float computed[64];
    for (std::size_t point = 0; point < count; ++point) {
        float real = static_cast<float>(input[4 + 2 * point]) / 16.0f;
        float imag = static_cast<float>(input[5 + 2 * point]) / 16.0f;
        for (std::int64_t step = 0; step < iterations; ++step) {
            const float real_square = real * real;
            const float imag_square = imag * imag;
            const float real_imag = real * imag;
            const float imag_real = imag * real;
            const float next_real = (real_square - imag_square) + cr;
            const float next_imag = (real_imag + imag_real) + ci;
            if (!(next_real <= 3.402823466e38f && next_real >= -3.402823466e38f) ||
                !(next_imag <= 3.402823466e38f && next_imag >= -3.402823466e38f)) return -1;
            real = next_real;
            imag = next_imag;
        }
        computed[2 * point] = real;
        computed[2 * point + 1] = imag;
    }
    for (std::size_t component = 0; component < 2 * count; ++component)
        put_f32_le(output, component * 4, computed[component]);
    return static_cast<std::int64_t>(needed);
}

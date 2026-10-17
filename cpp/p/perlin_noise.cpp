#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_dimension = 8;
constexpr std::size_t max_input_elements = 5;
constexpr std::size_t max_parseable_input_elements = 6;
constexpr std::size_t max_output_elements = max_dimension * max_dimension;
constexpr std::uint64_t java_multiplier = UINT64_C(0x5DEECE66D);
constexpr std::uint64_t java_addend = UINT64_C(0xB);
constexpr std::uint64_t java_mask = (UINT64_C(1) << 48) - 1;

float rounded_add(float a, float b) { volatile float value = a + b; return value; }
float rounded_sub(float a, float b) { volatile float value = a - b; return value; }
float rounded_mul(float a, float b) { volatile float value = a * b; return value; }
float rounded_div(float a, float b) { volatile float value = a / b; return value; }

std::uint32_t java_next(std::uint64_t& state, unsigned bits) {
    state = (state * java_multiplier + java_addend) & java_mask;
    return static_cast<std::uint32_t>(state >> (48 - bits));
}

float interpolate(float a, float b, float alpha) {
    const float one_minus_alpha = rounded_sub(1.0f, alpha);
    const float left = rounded_mul(a, one_minus_alpha);
    const float right = rounded_mul(alpha, b);
    return rounded_add(left, right);
}

bool exact_integer(double value, double minimum, double maximum) {
    return value == value && value >= minimum && value <= maximum && static_cast<std::int64_t>(value) == value;
}
}

extern "C" std::int64_t perlin_noise(const double* input, std::size_t length,
    double* output, std::size_t output_capacity) {
    if (input == nullptr || length < 4 || length > max_parseable_input_elements) return -1;
    if (length != max_input_elements) return -1;
    if (!exact_integer(input[0], 1.0, 8.0) || !exact_integer(input[1], 1.0, 8.0) ||
        !exact_integer(input[2], 1.0, 4.0) || !exact_integer(input[4], 0.0, 2147483647.0) ||
        (input[3] != 0.5 && input[3] != 0.75 && input[3] != 1.0)) return -1;

    const int width = static_cast<int>(input[0]), height = static_cast<int>(input[1]);
    const int octave_count = static_cast<int>(input[2]);
    const auto seed = static_cast<std::uint64_t>(input[4]);
    const std::size_t count = static_cast<std::size_t>(width) * static_cast<std::size_t>(height);
    float base[max_output_elements]{};
    float layers[4 * max_output_elements]{};
    float result[max_output_elements]{};

    std::uint64_t state = (seed ^ java_multiplier) & java_mask;
    for (int x = 0; x < width; ++x) for (int y = 0; y < height; ++y)
        base[x * height + y] = rounded_div(static_cast<float>(java_next(state, 24)), 16777216.0f);

    for (int octave = 0; octave < octave_count; ++octave) {
        const int period = 1 << octave;
        const float frequency = rounded_div(1.0f, static_cast<float>(period));
        float* layer = layers + static_cast<std::size_t>(octave) * max_output_elements;
        for (int x = 0; x < width; ++x) {
            const int x0 = (x / period) * period, x1 = (x0 + period) % width;
            const float horizontal = rounded_mul(static_cast<float>(x - x0), frequency);
            for (int y = 0; y < height; ++y) {
                const int y0 = (y / period) * period, y1 = (y0 + period) % height;
                const float vertical = rounded_mul(static_cast<float>(y - y0), frequency);
                const float top = interpolate(base[x0 * height + y0], base[x1 * height + y0], horizontal);
                const float bottom = interpolate(base[x0 * height + y1], base[x1 * height + y1], horizontal);
                layer[x * height + y] = interpolate(top, bottom, vertical);
            }
        }
    }

    float amplitude = 1.0f, total_amplitude = 0.0f;
    const float persistence = static_cast<float>(input[3]);
    for (int octave = octave_count - 1; octave >= 0; --octave) {
        amplitude = rounded_mul(amplitude, persistence);
        total_amplitude = rounded_add(total_amplitude, amplitude);
        const float* layer = layers + static_cast<std::size_t>(octave) * max_output_elements;
        for (std::size_t i = 0; i < count; ++i) result[i] = rounded_add(result[i], rounded_mul(layer[i], amplitude));
    }
    const float inverse_total = rounded_div(1.0f, total_amplitude);
    for (std::size_t i = 0; i < count; ++i) result[i] = rounded_mul(result[i], inverse_total);

    if (output == nullptr || output_capacity < count) return -2;
    for (std::size_t i = 0; i < count; ++i) output[i] = static_cast<double>(result[i]);
    return static_cast<std::int64_t>(count);
}

#include <cstddef>
#include <cstdint>

namespace {
constexpr int64_t max_iterations = 256;
constexpr size_t vector_length = 2048;

}

extern "C" int64_t misc_fp_convert(const double *input, size_t input_length,
                                  double *output, size_t output_capacity)
{
    if (input == nullptr || input_length != 1) return -1;
    const double requested = input[0];
    if (!(requested >= 1.0 && requested <= static_cast<double>(max_iterations)) ||
        requested != static_cast<double>(static_cast<int64_t>(requested))) return -1;
    if (output == nullptr || output_capacity < 1) return -2;

    const int64_t iterations = static_cast<int64_t>(requested);
    float x[vector_length];
    float y[vector_length];
    float a = 0.0f;
    float b = 1.0f;
    double total = 0.0;
    for (int64_t iteration = 0; iteration < iterations; ++iteration) {
        if (iteration % 10 != 0) {
            a = 0.0f;
            b = 1.0f;
        } else {
            a += 0.1f;
            b += 0.2f;
        }
        for (size_t index = 0; index < vector_length; ++index) {
            x[index] = a + static_cast<float>(index);
            y[index] = b + static_cast<float>(index);
        }
        double accumulator = 0.0;
        for (size_t index = 0; index < vector_length; ++index)
            accumulator += static_cast<double>(x[index]) * static_cast<double>(y[index]);
        total += accumulator;
    }
    output[0] = total;
    return 1;
}

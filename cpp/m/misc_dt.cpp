#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int64_t max_iterations = 128;
constexpr size_t max_vector_size = 64;
}

extern "C" int64_t misc_dt(const double *input, size_t input_length,
                            double *output, size_t output_capacity)
{
    if (input == nullptr || input_length != 2) return -1;
    const double requested_iterations = input[0];
    const double requested_size = input[1];
    if (!(requested_iterations >= 1.0 && requested_iterations <= static_cast<double>(max_iterations)) ||
        requested_iterations != static_cast<double>(static_cast<int64_t>(requested_iterations)) ||
        !(requested_size >= 1.0 && requested_size <= static_cast<double>(max_vector_size)) ||
        requested_size != static_cast<double>(static_cast<size_t>(requested_size))) return -1;
    const int64_t iterations = static_cast<int64_t>(requested_iterations);
    const size_t size = static_cast<size_t>(requested_size);
    if (output == nullptr || output_capacity < size) return -2;

    double numerator[max_vector_size];
    double denominator[max_vector_size];
    for (size_t index = 0; index < size; ++index) {
        numerator[index] = 1.0000001 * static_cast<double>(::cosf(static_cast<float>(size - index)));
        denominator[index] = 1.0 + 1e-10 * static_cast<double>(::sinf(static_cast<float>(index)));
    }
    for (int64_t iteration = 0; iteration < iterations; ++iteration)
        for (size_t index = 0; index < size; ++index)
            numerator[index] /= denominator[index];

    for (size_t index = 0; index < size; ++index) output[index] = numerator[index];
    return static_cast<int64_t>(size);
}

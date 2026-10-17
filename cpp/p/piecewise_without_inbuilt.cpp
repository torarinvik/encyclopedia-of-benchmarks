#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t piecewise_without_inbuilt(
    const double *input, std::size_t input_length,
    double *output, std::size_t output_capacity) {
    if (input == nullptr || input_length != 1) return -1;
    const double x = input[0];
    if (!std::isfinite(x) || x < -10.0 || x > 10.0) return -1;

    const double y = x <= -0.5 ? 0.0 : (x < 0.5 ? x : 1.0);
    if (output == nullptr || output_capacity < 1) return -2;
    output[0] = y;
    return 1;
}

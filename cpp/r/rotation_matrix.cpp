#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double max_angle = 1000.0;
}

extern "C" std::int64_t rotation_matrix(const double *input, std::size_t input_length,
                                         double *output, std::size_t output_capacity)
{
    if (input == nullptr || input_length != 1) return -1;
    const double theta = input[0];
    if (!std::isfinite(theta) || theta < -max_angle || theta > max_angle) return -1;
    const double cosine = std::cos(theta);
    const double sine = std::sin(theta);
    const double matrix[4] = {cosine, -sine, sine, cosine};
    if (output == nullptr || output_capacity < 4) return -2;
    for (std::size_t index = 0; index < 4; ++index) output[index] = matrix[index];
    return 4;
}

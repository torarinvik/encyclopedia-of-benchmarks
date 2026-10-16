#include <cmath>
#include <cstddef>
#include <cstdint>

static constexpr double INPUT_LIMIT = 1000000.0;
static constexpr double DENOMINATOR_FLOOR = 0.000001;
static constexpr double OUTPUT_LIMIT = 1.0e25;

extern "C" std::int64_t vector3_perspective_projection(const double *input, std::size_t input_len,
                                                        double *output, std::size_t output_capacity) {
    if (input == nullptr || input_len != 5) return -1;
    for (std::size_t i = 0; i < 5; ++i) {
        if (!std::isfinite(input[i]) || std::fabs(input[i]) > INPUT_LIMIT) return -1;
    }
    const double denominator = input[2] + input[4];
    if (std::fabs(denominator) < DENOMINATOR_FLOOR) return -1;
    const double x = ((input[0] * input[4]) / denominator) * input[3];
    const double y = ((input[1] * input[4]) / denominator) * input[3];
    if (!std::isfinite(x) || !std::isfinite(y) || std::fabs(x) > OUTPUT_LIMIT ||
        std::fabs(y) > OUTPUT_LIMIT) return -1;
    if (output == nullptr || output_capacity < 2) return -2;
    output[0] = x;
    output[1] = y;
    return 2;
}

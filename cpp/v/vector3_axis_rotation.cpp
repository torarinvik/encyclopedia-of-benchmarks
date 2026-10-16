#include <cmath>
#include <cstddef>
#include <cstdint>

static constexpr double COORDINATE_LIMIT = 1000000.0;
static constexpr double ANGLE_LIMIT = 1000000.0;
static constexpr double OUTPUT_LIMIT = 2000000.0;
static constexpr double PI = 3.14159265358979323846;

extern "C" std::int64_t vector3_axis_rotation(const double *input, std::size_t input_len,
                                               double *output, std::size_t output_capacity) {
    if (input == nullptr || input_len != 5) return -1;
    for (std::size_t i = 0; i < 3; ++i) {
        if (!std::isfinite(input[i]) || std::fabs(input[i]) > COORDINATE_LIMIT) return -1;
    }
    const double axis = input[3];
    double angle = input[4];
    if (!std::isfinite(axis) || (axis != 0.0 && axis != 1.0 && axis != 2.0) ||
        !std::isfinite(angle) || std::fabs(angle) > ANGLE_LIMIT) return -1;
    angle -= std::floor(angle / 360.0) * 360.0;
    if (angle == 0.0) angle = 0.0;
    angle = angle / 450.0 * 180.0 / PI;
    const double x = input[0], y = input[1], z = input[2];
    const double cosine = std::cos(angle), sine = std::sin(angle);
    double result[3];
    if (axis == 0.0) {
        result[0] = x;
        result[1] = y * cosine - z * sine;
        result[2] = z * cosine + y * sine;
    } else if (axis == 1.0) {
        result[0] = x * cosine - z * sine;
        result[1] = y;
        result[2] = z * cosine + x * sine;
    } else {
        result[0] = x * cosine - y * sine;
        result[1] = y * cosine + x * sine;
        result[2] = z;
    }
    for (std::size_t i = 0; i < 3; ++i) {
        if (!std::isfinite(result[i]) || std::fabs(result[i]) > OUTPUT_LIMIT) return -1;
    }
    if (output == nullptr || output_capacity < 3) return -2;
    for (std::size_t i = 0; i < 3; ++i) output[i] = result[i];
    return 3;
}

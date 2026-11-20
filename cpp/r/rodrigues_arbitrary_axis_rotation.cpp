#include <cmath>
#include <cstddef>
#include <cstdint>
#include <algorithm>

static constexpr double COMPONENT_LIMIT = 1'000'000.0;
static constexpr double ANGLE_LIMIT = 6.283185307179586;
static constexpr double OUTPUT_LIMIT = 2'000'000.0;

extern "C" std::int64_t rodrigues_arbitrary_axis_rotation(
    const double *input, std::size_t input_len, double *output,
    std::size_t output_capacity) {
    if (input == nullptr || input_len != 7) return -1;
    for (std::size_t i = 0; i < 6; ++i) {
        if (!std::isfinite(input[i]) || std::abs(input[i]) > COMPONENT_LIMIT) return -1;
    }
    const double theta = input[6];
    if (!std::isfinite(theta) || std::abs(theta) > ANGLE_LIMIT) return -1;

    const double scale = std::max(std::abs(input[0]),
                                  std::max(std::abs(input[1]), std::abs(input[2])));
    if (scale == 0.0) return -1;
    const double qx = input[0] / scale;
    const double qy = input[1] / scale;
    const double qz = input[2] / scale;
    const double norm = std::sqrt((qx * qx + qy * qy) + qz * qz);
    if (!std::isfinite(norm) || norm == 0.0) return -1;
    const double nx = qx / norm;
    const double ny = qy / norm;
    const double nz = qz / norm;
    const double vx = input[3], vy = input[4], vz = input[5];
    const double cosine = std::cos(theta), sine = std::sin(theta);
    const double one_minus_cosine = 1.0 - cosine;
    const double cx = ny * vz - nz * vy;
    const double cy = nz * vx - nx * vz;
    const double cz = nx * vy - ny * vx;
    const double dot = (nx * vx + ny * vy) + nz * vz;
    const double result[3] = {
        (vx * cosine + cx * sine) + (nx * dot) * one_minus_cosine,
        (vy * cosine + cy * sine) + (ny * dot) * one_minus_cosine,
        (vz * cosine + cz * sine) + (nz * dot) * one_minus_cosine,
    };
    for (double value : result) {
        if (!std::isfinite(value) || std::abs(value) > OUTPUT_LIMIT) return -1;
    }
    if (output == nullptr || output_capacity < 3) return -2;
    for (std::size_t i = 0; i < 3; ++i) output[i] = result[i];
    return 3;
}

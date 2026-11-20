#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define COMPONENT_LIMIT 1000000.0
#define ANGLE_LIMIT 6.283185307179586
#define OUTPUT_LIMIT 2000000.0

int64_t rodrigues_arbitrary_axis_rotation(const double *input, size_t input_len,
                                          double *output, size_t output_capacity) {
    if (input == NULL || input_len != 7) return -1;
    for (size_t i = 0; i < 6; ++i) {
        if (!isfinite(input[i]) || fabs(input[i]) > COMPONENT_LIMIT) return -1;
    }
    const double theta = input[6];
    if (!isfinite(theta) || fabs(theta) > ANGLE_LIMIT) return -1;

    const double scale = fmax(fabs(input[0]), fmax(fabs(input[1]), fabs(input[2])));
    if (scale == 0.0) return -1;
    const double qx = input[0] / scale;
    const double qy = input[1] / scale;
    const double qz = input[2] / scale;
    const double norm = sqrt((qx * qx + qy * qy) + qz * qz);
    if (!isfinite(norm) || norm == 0.0) return -1;
    const double nx = qx / norm;
    const double ny = qy / norm;
    const double nz = qz / norm;
    const double vx = input[3], vy = input[4], vz = input[5];
    const double cosine = cos(theta), sine = sin(theta);
    const double one_minus_cosine = 1.0 - cosine;
    const double cx = ny * vz - nz * vy;
    const double cy = nz * vx - nx * vz;
    const double cz = nx * vy - ny * vx;
    const double dot = (nx * vx + ny * vy) + nz * vz;
    double result[3];
    result[0] = (vx * cosine + cx * sine) + (nx * dot) * one_minus_cosine;
    result[1] = (vy * cosine + cy * sine) + (ny * dot) * one_minus_cosine;
    result[2] = (vz * cosine + cz * sine) + (nz * dot) * one_minus_cosine;
    for (size_t i = 0; i < 3; ++i) {
        if (!isfinite(result[i]) || fabs(result[i]) > OUTPUT_LIMIT) return -1;
    }
    if (output == NULL || output_capacity < 3) return -2;
    for (size_t i = 0; i < 3; ++i) output[i] = result[i];
    return 3;
}

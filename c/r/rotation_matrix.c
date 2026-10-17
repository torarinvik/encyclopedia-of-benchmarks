#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_ANGLE 1000.0

int64_t rotation_matrix(const double *input, size_t input_length,
                        double *output, size_t output_capacity)
{
    if (input == NULL || input_length != 1) return -1;
    const double theta = input[0];
    if (!isfinite(theta) || theta < -MAX_ANGLE || theta > MAX_ANGLE) return -1;
    const double cosine = cos(theta);
    const double sine = sin(theta);
    const double matrix[4] = {cosine, -sine, sine, cosine};
    if (output == NULL || output_capacity < 4) return -2;
    for (size_t index = 0; index < 4; ++index) output[index] = matrix[index];
    return 4;
}

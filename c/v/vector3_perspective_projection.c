#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INPUT_LIMIT 1000000.0
#define DENOMINATOR_FLOOR 0.000001
#define OUTPUT_LIMIT 1.0e25

int64_t vector3_perspective_projection(const double *input, size_t input_len,
                                       double *output, size_t output_capacity) {
    if (input == NULL || input_len != 5) return -1;
    for (size_t i = 0; i < 5; ++i) {
        if (!isfinite(input[i]) || fabs(input[i]) > INPUT_LIMIT) return -1;
    }
    const double denominator = input[2] + input[4];
    if (fabs(denominator) < DENOMINATOR_FLOOR) return -1;
    const double x = ((input[0] * input[4]) / denominator) * input[3];
    const double y = ((input[1] * input[4]) / denominator) * input[3];
    if (!isfinite(x) || !isfinite(y) || fabs(x) > OUTPUT_LIMIT || fabs(y) > OUTPUT_LIMIT) return -1;
    if (output == NULL || output_capacity < 2) return -2;
    output[0] = x;
    output[1] = y;
    return 2;
}

#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define COMPONENT_LIMIT 1000000.0
#define EPSILON 1e-9

static float dot_product(const float a[3], const float b[3]) {
    float dot = a[0] * b[0];
    dot += a[1] * b[1];
    dot += a[2] * b[2];
    return dot;
}

static float vector_norm(const float vector[3]) {
    return sqrtf(dot_product(vector, vector));
}

int64_t vectors_3d(const double *input, size_t input_len,
                   double *output, size_t output_capacity) {
    if (input == NULL || input_len == 0 || !isfinite(input[0]) ||
        input[0] < 0.0 || input[0] > 7.0 || floor(input[0]) != input[0]) return -1;
    const int operation = (int)input[0];
    const size_t required_length = operation <= 3 || operation == 7 ? 7 : 4;
    if (input_len != required_length) return -1;

    float a[3], b[3] = {0.0f, 0.0f, 0.0f};
    for (size_t index = 0; index < 3; ++index) {
        const double value = input[1 + index];
        if (!isfinite(value) || fabs(value) > COMPONENT_LIMIT) return -1;
        a[index] = (float)value;
    }
    if (required_length == 7) {
        for (size_t index = 0; index < 3; ++index) {
            const double value = input[4 + index];
            if (!isfinite(value) || fabs(value) > COMPONENT_LIMIT) return -1;
            b[index] = (float)value;
        }
    }

    double result[9] = {0.0};
    size_t result_length;
    switch (operation) {
        case 0:
            result_length = 3;
            for (size_t index = 0; index < 3; ++index) result[index] = (double)(a[index] + b[index]);
            break;
        case 1:
            result_length = 3;
            for (size_t index = 0; index < 3; ++index) result[index] = (double)(a[index] - b[index]);
            break;
        case 2:
            result_length = 1;
            result[0] = (double)dot_product(a, b);
            break;
        case 3:
            result_length = 3;
            result[0] = (double)(a[1] * b[2] - a[2] * b[1]);
            result[1] = (double)(-a[0] * b[2] + a[2] * b[0]);
            result[2] = (double)(a[0] * b[1] - a[1] * b[0]);
            break;
        case 4:
            result_length = 1;
            result[0] = (double)vector_norm(a);
            break;
        case 5: {
            result_length = 3;
            const float norm = vector_norm(a);
            if (norm < EPSILON) break;
            /* Preserve the source defect: exact unit input leaves the zero initializer intact. */
            if (norm != 1.0f) {
                for (size_t index = 0; index < 3; ++index) result[index] = (double)(a[index] / norm);
            }
            break;
        }
        case 6:
            result_length = 9;
            result[0] = 0.0; result[1] = (double)-a[2]; result[2] = (double)a[1];
            result[3] = (double)a[2]; result[4] = 0.0; result[5] = (double)-a[0];
            result[6] = (double)-a[1]; result[7] = (double)a[0]; result[8] = 0.0;
            break;
        default: {
            result_length = 1;
            const float norm_a = vector_norm(a);
            const float norm_b = vector_norm(b);
            if (norm_a < EPSILON || norm_b < EPSILON) {
                result[0] = acos(2.0);
            } else {
                const float cosine = dot_product(a, b) / (norm_a * norm_b);
                result[0] = acos((double)cosine);
            }
            break;
        }
    }

    if (output == NULL || output_capacity < result_length) return -2;
    for (size_t index = 0; index < result_length; ++index) output[index] = result[index];
    return (int64_t)result_length;
}

#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1L)
#define OUTPUT_ERROR (-2L)
#define INPUT_LENGTH 6
#define MAX_PARSEABLE_INPUT_LENGTH 7

static int in_range(double value, double minimum, double maximum)
{
    return value >= minimum && value <= maximum;
}

long sir(const double *input, size_t input_length, double *output, size_t output_capacity)
{
    if (input == NULL || input_length < INPUT_LENGTH || input_length > MAX_PARSEABLE_INPUT_LENGTH)
        return INVALID_RESULT;
    if (input_length != INPUT_LENGTH) return INVALID_RESULT;

    const double s = input[0];
    const double i = input[1];
    const double r = input[2];
    const double beta = input[3];
    const double k = input[4];
    const double time = input[5];
    if (!in_range(s, 0.0, 1000000.0) || !in_range(i, 0.0, 1000000.0) ||
        !in_range(r, 0.0, 1000000.0) || !in_range(beta, 0.0, 0.001) ||
        !in_range(k, 0.0, 1.0) || !in_range(time, 0.0, 140.0))
        return INVALID_RESULT;

    const double d_s = ((-beta) * s) * i;
    const double d_i_infection = (beta * s) * i;
    const double d_i_recovery = k * i;
    const double d_i = d_i_infection - d_i_recovery;
    const double d_r = k * i;

    if (output == NULL || output_capacity < 3) return OUTPUT_ERROR;
    output[0] = d_s;
    output[1] = d_i;
    output[2] = d_r;
    return 3;
}

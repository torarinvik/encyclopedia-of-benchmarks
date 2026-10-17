#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MIN_SAMPLE_COUNT 2u
#define MAX_SAMPLE_COUNT 32u
#define MAX_PARSEABLE_INPUT_LENGTH 66u
#define MAX_OUTPUT_ELEMENTS 2u

static int exact_integer_in_range(double value, int minimum, int maximum)
{
    if (!isfinite(value) || value < (double)minimum || value > (double)maximum) return 0;
    return value == (double)(int)value;
}

static double rounded_divide(double numerator, double denominator)
{
    volatile double result = numerator / denominator;
    return result;
}

int64_t linearregressionrawr(const double *input, size_t input_length,
                             double *output, size_t output_capacity)
{
    if (input == NULL || input_length == 0u ||
        input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    for (size_t index = 0u; index < input_length; ++index) {
        if (!isfinite(input[index])) return -1;
    }

    if (!exact_integer_in_range(input[0], (int)MIN_SAMPLE_COUNT,
                                (int)MAX_SAMPLE_COUNT)) return -1;
    const size_t sample_count = (size_t)input[0];
    if (input_length != 1u + 2u * sample_count) return -1;

    int64_t predictor_sum = 0;
    int64_t response_sum = 0;
    int64_t cross_product_sum = 0;
    int64_t predictor_square_sum = 0;
    int64_t first_predictor = 0;
    int predictors_are_constant = 1;
    for (size_t index = 0u; index < sample_count; ++index) {
        const double predictor_value = input[1u + index];
        const double response_value = input[1u + sample_count + index];
        if (!exact_integer_in_range(predictor_value, -4, 4) ||
            !exact_integer_in_range(response_value, -16, 16)) return -1;

        const int64_t predictor = (int64_t)predictor_value;
        const int64_t response = (int64_t)response_value;
        if (index == 0u) first_predictor = predictor;
        else if (predictor != first_predictor) predictors_are_constant = 0;

        predictor_sum += predictor;
        response_sum += response;
        cross_product_sum += predictor * response;
        predictor_square_sum += predictor * predictor;
    }
    if (predictor_sum != 0 || predictors_are_constant || predictor_square_sum == 0) return -1;

    const double results[MAX_OUTPUT_ELEMENTS] = {
        rounded_divide((double)response_sum, (double)sample_count),
        rounded_divide((double)cross_product_sum, (double)predictor_square_sum)
    };
    if (output == NULL || output_capacity < MAX_OUTPUT_ELEMENTS) return -2;
    for (size_t index = 0u; index < MAX_OUTPUT_ELEMENTS; ++index) output[index] = results[index];
    return (int64_t)MAX_OUTPUT_ELEMENTS;
}
